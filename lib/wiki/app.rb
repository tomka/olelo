# -*- coding: utf-8 -*-
require 'logger'
require 'wiki/timer'
require 'wiki/routing'
require 'wiki/resource'
require 'wiki/helper'
require 'wiki/user'
require 'wiki/plugin'

module Wiki
  # Main class of the application
  class App
    include Routing
    include AppHelper
    include Templates
    patterns :path => PATH_PATTERN, :version => VERSION_PATTERN
    attr_reader :repository, :logger, :user

    def user=(user)
      @user = user
      if user && !user.anonymous?
        session[:user] = user
      else
        session.delete(:user)
      end
    end

    def initialize(app = nil, opts = {})
      @app = app
      @logger = opts[:logger] || Logger.new(nil)

      I18n.load_locale(File.join(File.dirname(__FILE__), 'locale.yml'))

      logger.debug 'Opening repository'
      @repository = Gitrb::Repository.new(:path => Config.git.repository, :create => true,
                                          :bare => true, :logger => logger)

      Plugin.logger = logger
      Plugin.dir = File.join(Config.root, 'plugins')
      Plugin.load('*')
      Plugin.start

      logger.debug self.class.dump_routes
    end

    def dup
      super.instance_eval do
        @repository = @repository.dup
        self
      end
    end

    @plugin_assets = nil
    class<< self
      attr_reader :plugin_assets

      def assets(*files)
        if !@plugin_assets
          @plugin_assets = {}
          get "/_/:file", :patterns => {:file => /.*/} do
            if path = self.class.plugin_assets[params[:file]]
              cache_control :last_modified => File.mtime(path), :max_age => :static
              send_file path
            else
              pass
            end
          end
        end
        name = File.dirname(Plugin.current.name)
        dir = File.dirname(Plugin.current.file)
        files.each do |file|
          Dir.glob(File.join(dir, file)).each do |path|
            @plugin_assets[name/path[dir.length+1..-1]] = path
          end
        end
      end
    end

    # Executed before each request
    hook(:before_routing) do
      @timer = Timer.new
      logger.debug request.env

      @user = session[:user]
      if !@user
        invoke_hook(:auto_login)
        @user ||= User.anonymous(request)
      end

      content_type 'application/xhtml+xml', :charset => 'utf-8'
    end

    # Handle 404s
    hook(NotFound) do |ex|
      if request.env['wiki.redirect_to_new']
        # Redirect to create new page if flag is set
        path = (params[:path]/'new').urlpath
        path += '?' + request.query_string if !request.query_string.blank?
        redirect path
      end
    end

    hook(StandardError) do |ex|
      if on_error
        @logger.error ex
        (ex.try(:messages) || [ex.message]).each {|msg| flash.error(msg) }
        halt haml(on_error)
      end
    end

    # Show wiki error page
    hook(Exception) do |ex|
      cache_control :no_cache => true
      @error = ex
      logger.error @error
      haml :error
    end

    get '/_/user' do
      haml :user, :layout => false
    end

    get '/' do
      redirect Config.main_page.urlpath
    end

    get '/login', '/signup' do
      haml :login
    end

    post '/login' do
      on_error :login
      self.user = User.authenticate(params[:user], params[:password])
      redirect session.delete(:goto) || '/'
    end

    post '/signup' do
      on_error :login
      self.user = User.create(params[:user], params[:password],
                              params[:confirm], params[:email])
      redirect '/'
    end

    get '/logout' do
      self.user = nil
      redirect '/'
    end

    get '/profile' do
      haml :profile
    end

    post '/profile' do
      on_error :profile
      if !user.anonymous?
        user.modify do |u|
          u.change_password(params[:oldpassword], params[:password], params[:confirm]) if !params[:password].blank?
          u.email = params[:email]
        end
        flash.info :changes_saved.t
        session[:user] = user
      end
      haml :profile
    end

    get '/changes/:version' do
      @commit = repository.get_commit(params[:version])
      cache_control :etag => @commit.sha, :last_modified => @commit.date
      @diff = repository.diff(@commit.parent.first && @commit.parent.first.sha, @commit.sha)
      haml :changes
    end

    get '/?:path?/history' do
      @resource = Resource.find!(repository, params[:path])
      cache_control :etag => @resource.commit.sha, :last_modified => @resource.commit.date
      haml :history
    end

    get '/:path/move' do
      @resource = Resource.find!(repository, params[:path])
      haml :move
    end

    get '/:path/delete' do
      @resource = Resource.find!(repository, params[:path])
      haml :delete
    end

    post '/:path/move' do
      on_error :move
      @resource = Resource.find!(repository, params[:path])
      with_hooks(:resource_move, @resource, params[:destination]) do
        @resource.move(params[:destination], user, params[:create_redirect])
      end
      redirect @resource.path.urlpath
    end

    delete '/:path' do
      pass if reserved_path?(params[:path])
      @resource = Resource.find!(repository, params[:path])
      with_hooks(:resource_delete, @resource) do
        @resource.delete(user)
      end
      haml :deleted
    end

    get '/?:path?/diff' do
      on_error :history
      @resource = Resource.find!(repository, params[:path])
      Wiki.check do |errors|
        errors << :from_missing.t if params[:from].blank?
        errors << :to_missing.t  if params[:to].blank?
      end
      @diff = @resource.diff(params[:from], params[:to])
      haml :diff
    end

    get '/:path/edit' do
      @resource = Page.find(repository, params[:path])
      redirect((params[:path]/'new').urlpath) if !@resource
      haml :edit
    end

    get '/?:path?/new', '/?:path?/upload' do
      on_error :new
      if params[:path] && @resource = Resource.find(repository, params[:path])
        return haml(:edit) if @resource.page? && action?(:upload)
        redirect((params[:path]/(@resource.tree? ? 'new page' : 'edit')).urlpath)
      end
      @resource = Page.new(repository, params[:path])
      Wiki.error :reserved_path.t if reserved_path?(params[:path])
      haml :new
    end

    get '/?:path?/version/?:version?', '/:path' do
      begin
        pass if reserved_path?(params[:path])
        @resource = Resource.find!(repository, params[:path], params[:version])
        cache_control :etag => @resource.latest_commit.sha, :last_modified => @resource.latest_commit.date
        with_hooks(:page_show) do
          @content = @resource.try(:content)
          halt haml(:show)
        end
      rescue Resource::NotFound
        request.env['wiki.redirect_to_new'] = params[:version].blank?
        pass
      end
    end

    # Edit form sends put requests
    put '/:path' do
      on_error :edit
      @resource = Page.find!(repository, params[:path])

      # TODO: Implement conflict diffs
      Wiki.error :version_conflict.t if @resource.commit.sha != params[:version]

      if action?(:upload) && params[:file]
        with_hooks :page_save, @resource do
          @resource.write(params[:file][:tempfile], :file_uploaded.t(:path => @resource.path), user)
        end
      elsif action?(:edit) && params[:content]
        with_hooks :page_save, @resource do
          content = if params[:pos]
                      pos = [[0, params[:pos].to_i].max, @resource.content.size].min
                      len = [0, params[:len].to_i].max
                      @resource.content(0, pos) + params[:content] + @resource.content(pos + len, @resource.content.size)
                    else
                      params[:content]
                    end
          @resource.write(content, params[:message], user)
        end
      else
        redirect((@resource.path/'edit').urlpath)
      end
      redirect @resource.path.urlpath
    end

    # New form sends post request
    post '/', '/:path' do
      on_error :new

      pass if reserved_path?(params[:path])
      @resource = Page.new(repository, params[:path])
      if action?(:upload) && params[:file]
        with_hooks :page_save, @resource do
          @resource.write(params[:file][:tempfile], :file_uploaded.t(:path => @resource.path), user)
        end
      elsif action?(:new)
        with_hooks :page_save, @resource do
          @resource.write(params[:content], params[:message], user)
        end
      else
        redirect '/new'
      end
      redirect @resource.path.urlpath
    end

    private

    def reserved_path?(path)
      path = path.to_s.urlpath
      self.class.routes.any? do |method, routes|
        routes.any? do |name,pattern|
          name != '/:path' && (path =~ pattern || path =~ /#{pattern.source[0..-2]}\//)
        end
      end
    end

  end
end

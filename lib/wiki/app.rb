# -*- coding: utf-8 -*-
require 'logger'
require 'wiki/routing'
require 'wiki/resource'
require 'wiki/helper'
require 'wiki/user'
require 'wiki/engine'
require 'wiki/plugin'

module Wiki
  # Main class of the application
  class App
    include Routing
    include Helper
    include Templates
    patterns :path => PATH_PATTERN, :sha => SHA_PATTERN
    attr_reader :repository

    def initialize(app = nil, opts = {})
      @app = app
      @logger = opts[:logger] || Logger.new(nil)

      I18n.load_locale(File.join(File.dirname(__FILE__), 'locale.yml'))

      @logger.debug 'Opening repository'
      @repository = Gitrb::Repository.new(:path => Config.git.repository, :create => true,
                                          :bare => true, :logger => @logger)

      Plugin.logger = @logger
      Plugin.dir = File.join(Config.root, 'plugins')
      Plugin.load('*')
      Plugin.start

      @logger.debug self.class.dump_routes
    end

    def dup
      super.instance_eval do
        @repository = @repository.dup
        self
      end
    end

    class<< self
      attr_reader :plugin_files

      def static_files(*files)
        if !@plugin_files
          @plugin_files = {}
          get "/_/:file", :patterns => {:file => /.*/} do
            if path = self.class.plugin_files[params[:file]]
              cache_control :last_modified => File.mtime(path), :static => true
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
            @plugin_files[name/path[dir.length+1..-1]] = path
          end
        end
      end
    end

    # Executed before each request
    add_hook(:before_routing) do
      start_timer
      @logger.debug request.env

      @user = session[:user]
      if !@user
        invoke_hook(:auto_login)
        @user ||= User.anonymous(request)
      end

      content_type('text/html', :charset => 'utf-8')
    end

    # Handle 404s
    add_hook(NotFound) do |ex|
      if request.env['wiki.redirect_to_new']
        # Redirect to create new page if flag is set
        redirect(params[:sha] ? params[:path].urlpath : (params[:path]/'new').urlpath)
      else
        no_caching
        @error = ex
        haml :error
      end
    end

    # Show wiki error page
    add_hook(Exception) do |ex|
      no_caching
      @error = ex
      @logger.error @error
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
      begin
        session[:user] = @user = User.authenticate(params[:user], params[:password])
	redirect session.delete(:goto) || '/'
      rescue StandardError => error
        message :error, error
        haml :login
      end
    end

    post '/signup' do
      begin
        session[:user] = @user = User.create(params[:user], params[:password],
                                             params[:confirm], params[:email])
        redirect '/'
      rescue StandardError => error
        message :error, error
        haml :login
      end
    end

    get '/logout' do
      session[:user] = @user = nil
      redirect '/'
    end

    get '/profile' do
      haml :profile
    end

    post '/profile' do
      if !@user.anonymous?
        begin
          @user.modify do |user|
            user.change_password(params[:oldpassword], params[:password], params[:confirm]) if !params[:password].blank?
            user.email = params[:email]
          end
          message :info, :changes_saved.t
          session[:user] = @user
        rescue StandardError => error
          message :error, error
        end
      end
      haml :profile
    end

    get '/commit/:sha' do
      @commit = repository.get_commit(params[:sha])
      cache_control :etag => @commit.sha, :last_modified => @commit.date
      @diff = repository.diff(@commit.parent.first.sha, @commit.sha)
      haml :commit
    end

    get '/?:path?/archive' do
      tree = Tree.find!(repository, params[:path])
      cache_control :etag => tree.sha, :last_modified => tree.commit.date
      send_file(tree.archive, :content_type => 'application/zip', :filename => "#{tree.safe_name}.zip")
    end

    get '/?:path?/history' do
      @resource = Resource.find!(repository, params[:path])
      cache_control :etag => @resource.sha, :last_modified => @resource.commit.date
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
      begin
        @resource = Resource.find!(repository, params[:path])
        invoke_hook(:resource_move, @resource, params[:destination]) { @resource.move(params[:destination], @user) }
        redirect @resource.path.urlpath
      rescue StandardError => error
	message :error, error
        haml :move
      end
    end

    post '/:path/delete' do
      @resource = Resource.find!(repository, params[:path])
      invoke_hook(:resource_delete, @resource) { @resource.delete(@user) }
      haml :deleted
    end

    get '/?:path?/diff' do
      @resource = Resource.find!(repository, params[:path])
      begin
        Wiki.forbid('From not selected' => params[:from].blank?, 'To not selected' => params[:to].blank?)
        @diff = @resource.diff(params[:from], params[:to])
        haml :diff
      rescue StandardError => error
        message :error, error
        haml :history
      end
    end

    get '/:path/edit', '/:path/upload' do
      begin
        @resource = Page.find!(repository, params[:path])
        haml :edit
      rescue Resource::NotFound
        pass if action? :upload # Pass to next handler because /upload is used twice
        raise
      end
    end

    get '/new', '/upload', '/:path/new', '/:path/upload' do
      begin
        # Redirect to edit for existing pages
        if !params[:path].blank? && Resource.find(repository, params[:path])
          redirect (params[:path]/'edit').urlpath
        end
        @resource = Page.new(repository, params[:path])
        Wiki.forbid(:reserved_path.t => reserved_path?(params[:path]))
      rescue StandardError => error
	message :error, error
      end
      haml :new
    end

    get '/version/:sha', '/:path/version/:sha', '/:path' do
      begin
        pass if reserved_path?(params[:path])

        @resource = Resource.find!(repository, params[:path], params[:sha])
        cache_control :etag => @resource.latest_commit.sha, :last_modified => @resource.latest_commit.date

        @engine = Engine.find!(@resource, params[:output])
        @content = @engine.render(@resource, params, no_cache?)
        if @engine.layout?
          haml :resource
        else
          content_type @engine.mime(@resource).to_s
          @content
        end
      rescue Resource::NotFound
        request.env['wiki.redirect_to_new'] = true
        pass
      end
    end

    # Edit form sends put requests
    put '/:path' do
      @resource = Page.find!(repository, params[:path])
      begin
        Wiki.forbid(:version_conflict.t => @resource.commit.sha != params[:sha]) # TODO: Implement conflict diffs
        if action?(:upload) && params[:file]
          invoke_hook :page_save, @resource do
            @resource.write(params[:file][:tempfile], :file_uploaded.t, @user)
          end
        elsif action?(:edit) && params[:content]
          invoke_hook :page_save, @resource do
            content = if params[:pos]
                        pos = [[0, params[:pos].to_i].max, @resource.content.size].min
                        len = [0, params[:len].to_i].max
                        @resource.content(0, pos) + params[:content] + @resource.content(pos + len, @resource.content.size)
                      else
                        params[:content]
                      end
            @resource.write(content, params[:message], @user)
          end
        else
          redirect((@resource.path/'edit').urlpath)
        end
        redirect @resource.path.urlpath
      rescue StandardError => error
        message :error, error
        haml :edit
      end
    end

    # New form sends post request
    post '/', '/:path' do
      begin
        pass if reserved_path?(params[:path])
        @resource = Page.new(repository, params[:path])
        if action?(:upload) && params[:file]
          invoke_hook :page_save, @resource do
            @resource.write(params[:file][:tempfile], "File #{@resource.path} uploaded", @user)
          end
        elsif action?(:new)
          invoke_hook :page_save, @resource do
            @resource.write(params[:content], params[:message], @user)
          end
        else
          redirect '/new'
        end
        redirect @resource.path.urlpath
      rescue StandardError => error
	message :error, error
        haml :new
      end
    end

    private

    def reserved_path?(path)
      path = path.to_s.urlpath
      self.class.routes.any? do |method, routes|
        routes.any? do |name,pattern|
          name != '/:path' && pattern =~ path
        end
      end
    end

  end
end

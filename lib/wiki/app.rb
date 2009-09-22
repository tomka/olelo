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

    def initialize(app = nil, opts = {})
      @app = app
      @logger = opts[:logger] || Logger.new(nil)

      I18n.load_locale(File.join(File.dirname(__FILE__), 'locale.yml'))

      if File.exists?(Config.git.repository) && File.exists?(Config.git.workspace)
        @logger.info 'Opening repository'
        @repo = Git.open(Config.git.workspace, :repository => Config.git.repository,
                         :index => File.join(Config.git.repository, 'index'), :log => @logger)
      else
        @logger.info 'Initializing repository'
        @repo = Git.init(Config.git.workspace, :repository => Config.git.repository,
                         :index => File.join(Config.git.repository, 'index'), :log => @logger)
        page = Page.new(@repo, Config.main_page)
        page.write(:main_page_text.t, :initialize_repository.t)
        @logger.info 'Repository initialized'
      end

      Plugin.logger = @logger
      Plugin.dir = File.join(Config.root, 'plugins')
      Plugin.load('*')
      Plugin.start

      @logger.debug self.class.dump_routes
    end

    class<< self
      attr_reader :plugin_files

      def public_files(*files)
        if !@plugin_files
          @plugin_files = {}
          get "/sys/:file", :patterns => {:file => /.*/} do
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
        files.each { |file| @plugin_files[name/file] = File.join(dir, file) }
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

    get '/sys/user' do
      haml :user, :layout => false
    end

    get '/' do
      redirect Config.main_page.urlpath
    end

    get '/login', '/signup' do
      cache_control :static => true
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

    get "/:style.css" do
      begin
        # Try to use wiki version
        params[:output] = 'css'
        params[:path] = params[:style] + '.sass'
        show
      rescue Resource::NotFound
        pass if !%w(screen print reset).include?(params[:style])
        # Fallback to default style
        cache_control :max_age => 3600
        content_type 'text/css', :charset => 'utf-8'
        sass :"style/#{params[:style]}"
      end
    end

    get '/commit/:sha' do
      cache_control :etag => params[:sha], :validate_only => true
      @commit = @repo.gcommit(params[:sha])
      cache_control :etag => @commit.sha, :last_modified => @commit.date
      @diff = @repo.diff(@commit.parent, @commit.sha)
      haml :commit
    end

    get '/?:path?/archive' do
      tree = Tree.find!(@repo, params[:path])
      cache_control :etag => tree.sha, :last_modified => tree.commit.date
      archive = tree.archive
      send_file(archive, :content_type => 'application/x-tar-gz', :filename => "#{tree.safe_name}.tar.gz")
    end

    get '/?:path?/history' do
      @resource = Resource.find!(@repo, params[:path])
      cache_control :etag => @resource.sha, :last_modified => @resource.commit.date
      haml :history
    end

    get '/?:path?/diff' do
      @resource = Resource.find!(@repo, params[:path])
      begin
        forbid('From not selected' => params[:from].blank?, 'To not selected' => params[:to].blank?)
        cache_control :static => true
        @diff = @resource.diff(params[:from], params[:to])
        haml :diff
      rescue StandardError => error
        message :error, error
        haml :history
      end
    end

    get '/:path/edit', '/:path/upload' do
      begin
        @resource = Page.find!(@repo, params[:path])
        haml :edit
      rescue Resource::NotFound
        pass if action? :upload # Pass to next handler because /upload is used twice
        raise
      end
    end

    get '/new', '/upload', '/:path/new', '/:path/upload' do
      begin
        # Redirect to edit for existing pages
        if !params[:path].blank? && Resource.find(@repo, params[:path])
          redirect (params[:path]/'edit').urlpath
        end
        @resource = Page.new(@repo, params[:path])
        boilerplate
        forbid(:path_not_allowed.t => name_clash?(params[:path]))
      rescue StandardError => error
        message :error, error
      end
      haml :new
    end

    get '/:sha', '/:path/:sha', '/:path' do
      begin
        pass if name_clash?(params[:path])
        show
      rescue Resource::NotFound
        request.env['wiki.redirect_to_new'] = true
        pass
      end
    end

    # Edit form sends put requests
    put '/:path' do
      @resource = Page.find!(@repo, params[:path])
      begin
        forbid(:version_conflict.t => @resource.commit.sha != params[:sha]) # TODO: Implement conflict diffs
        if action?(:upload) && params[:file]
          invoke_hook :page_save, @resource do
            @resource.write(params[:file][:tempfile], :file_uploaded.t, @user.author)
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
            @resource.write(content, params[:message], @user.author)
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
        pass if name_clash?(params[:path])
        @resource = Page.new(@repo, params[:path])
        if action?(:upload) && params[:file]
          invoke_hook :page_save, @resource do
            @resource.write(params[:file][:tempfile], "File #{@resource.path} uploaded", @user.author)
          end
        elsif action?(:new)
          invoke_hook :page_save, @resource do
            @resource.write(params[:content], params[:message], @user.author)
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

    def name_clash?(path)
      path = path.to_s.urlpath
      patterns = self.class.routes.values.inject([], &:+).map {|x| x[1] }.uniq

      # Remove overly general patterns
      patterns.delete(%r{^/(#{PATH_PATTERN})$}) # Path
      patterns.delete(%r{^/(#{PATH_PATTERN})/(#{SHA_PATTERN})$}) # Path with unstrict sha
      patterns.delete(%r{^/(#{SHA_PATTERN})$}) # Root with unstrict sha

      # Add pattern to ensure availability of strict sha urls
      # Shortcut sha urls (e.g /Beef) can be overridden
      patterns << %r{^/(#{STRICT_SHA_PATTERN})$}
      patterns << %r{^/(#{PATH_PATTERN})/(#{STRICT_SHA_PATTERN})$}

      patterns.any? {|pattern| pattern =~ path }
    end

    # Show resource
    def show
      @resource = Resource.find!(@repo, params[:path], params[:sha])
      if @resource.current?
        cache_control :etag => @resource.latest_commit.sha, :last_modified => @resource.latest_commit.date
      else
        cache_control :static => true
      end

      @engine = Engine.find!(@resource, params[:output])
      @content = @engine.render(@resource, params, no_cache?)
      if @engine.layout?
        haml :resource
      else
        content_type @engine.mime(@resource).to_s
        @content
      end
    end

    # Boilerplate for new pages
    def boilerplate
      if @resource.path =~ /^\w+\.sass$/
	name = File.join(Config.root, 'views', 'style', @resource.path)
	params[:content] = File.read(name) if File.file?(name)
      end
    end

  end
end

module Olelo
  # Main class of the application
  class Application
    include Util
    include Routing
    include Templates
    include ApplicationHelper
    include AttributeEditor

    attribute_editor do
      attribute :title, :string
      attribute :mime,  :string
    end

    patterns :path => Page::PATH_PATTERN
    attr_reader :logger, :user, :timer, :page
    attr_setter :on_error

    class<< self
      attr_accessor :theme_links
      attr_accessor :reserved_paths
    end

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
      Initializer.init(@logger)
    end

    # Executed before each request
    before :routing do
      @timer = Timer.start

      # Set request ip as progname
      @logger = logger.dup
      logger.progname = request.ip

      logger.debug env

      @user = session[:user]
      if !@user
        invoke_hook(:auto_login)
        @user ||= User.anonymous(request)
      end

      response['Content-Type'] = 'application/xhtml+xml;charset=utf-8'
    end

    # Handle 404s
    hook NotFound do |error|
      logger.debug(error)
      cache_control :no_cache => true
      halt render(:not_found, :locals => {:error => error})
    end

    hook StandardError do |error|
      if on_error
        logger.error error
        (error.try(:messages) || [error.message]).each {|msg| flash.error(msg) }
        halt render(on_error)
      end
    end

    # Show wiki error page
    hook Exception do |error|
      logger.error(error)
      cache_control :no_cache => true
      render :error, :locals => {:error => error}
    end

    get '/login' do
      render :login
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
      raise 'Anonymous users don not have a profile.' if user.anonymous?
      render :profile
    end

    post '/profile' do
      raise 'Anonymous users don not have a profile.' if user.anonymous?
      on_error :profile
      user.modify do |u|
        u.change_password(params[:oldpassword], params[:password], params[:confirm]) if !params[:password].blank?
        u.email = params[:email]
      end
      flash.info :changes_saved.t
      session[:user] = user
      render :profile
    end

    get '/changes/:version(/:path)' do
      @page = Page.find!(params[:path])
      @version = Version.find!(params[:version])
      @diff = page.diff(nil, @version)
      cache_control :etag => @version, :last_modified => @version.date
      render :changes
    end

    get '/history(/:path)' do
      @page = Page.find!(params[:path])
      @per_page = 30
      @page_nr = params[:page].to_i
      @history = page.history(@page_nr * @per_page)
      @last_page = @page_nr + @history.length / @per_page
      @history = @history[0...@per_page]
      cache_control :etag => page.version, :last_modified => page.version.date
      render :history, :layout => !request.xhr?
    end

    get '/move/:path' do
      @page = Page.find!(params[:path])
      render :move
    end

    get '/delete/:path' do
      @page = Page.find!(params[:path])
      render :delete
    end

    post '/move/:path' do
      on_error :move
      Page.transaction(:page_moved.t(:page => params[:path].cleanpath, :destination => params[:destination].cleanpath), user) do
        @page = Page.find!(params[:path])
        with_hooks(:move, @page, params[:destination]) do
          page.move(params[:destination])
        end
      end
      redirect absolute_path(page)
    end

    get '/compare/:versions(/:path)', :versions => '(?:\w+)\.{2,3}(?:\w+)' do
      @page = Page.find!(params[:path])
      versions = params[:versions].split(/\.{2,3}/)
      @diff = page.diff(versions.first, versions.last)
      render :compare
    end

    get '/compare(/:path)' do
      versions = params[:versions] || []
      redirect absolute_path(versions.size < 2 ? "#{params[:path]}/history" :
                             "/compare/#{versions.first}...#{versions.last}/#{params[:path]}")
    end

    get '/edit(/:path)' do
      @page = Page.find!(params[:path])
      render :edit
    end

    get '/new(/:path)' do
      @page = Page.new(params[:path])
      flash.error :reserved_path.t if reserved_path?(page.path)
      params[:path] = !page.root? && Page.find(page.path) ? page.path + '/' : page.path
      render :edit
    end

    def self.final_routes
      get '/version/:version(/:path)|/(:path)' do
        begin
          @page = Page.find!(params[:path], params[:version])
          cache_control :etag => page.version, :last_modified => page.version.date
          @menu_versions = true
          with_hooks(:show) do
            halt render(:show, :locals => {:content => page.try(:content)})
          end
        rescue NotFound
          redirect absolute_path('new'/params[:path].to_s) if params[:version].blank?
          raise
        end
      end

      delete '/:path' do
        Page.transaction(:page_deleted.t(:page => params[:path].cleanpath), user) do
          @page = Page.find!(params[:path])
          with_hooks(:delete, page) do
            page.delete
          end
        end
        render :deleted
      end

      post '/(:path)' do
        save_page
      end

      put '/(:path)' do
        save_page
      end
    end

    def save_page
      @page = request.put? ? Page.find!(params[:path]) : Page.new(params[:path])
      raise :reserved_path.t if reserved_path?(page.path)
      on_error :edit

      if params[:action] == 'edit' && params[:content]
        params[:content].gsub!("\r\n", "\n")
        with_hooks :save, page do
          Page.transaction(:page_edited.t(:page => page.title, :comment => params[:comment]), user) do
            page.content = if params[:pos]
                             [page.content[0, params[:pos].to_i].to_s,
                              params[:content],
                              page.content[params[:pos].to_i + params[:len].to_i .. -1]].join
                           else
                             params[:content]
                           end
            redirect absolute_path(page) if params[:close] && !page.modified?
            check do |errors|
              errors << :empty_comment.t if params[:comment].blank?
              errors << :version_conflict.t if !page.new? && page.version.to_s != params[:version]
              errors << :no_changes.t if !page.modified?
            end
            page.save
          end
          params.delete(:comment)
          flash.info :changes_saved.t
        end
      elsif params[:action] == 'upload' && params[:file]
        with_hooks :save, page do
          Page.transaction(:page_uploaded.t(:page => page.title), user) do
            raise :version_conflict.t if !page.new? && page.version.to_s != params[:version]
            page.content = params[:file][:tempfile]
            page.save
          end
          flash.info :changes_saved.t
        end
      elsif params[:action] == 'attributes'
        with_hooks :save, page do
          Page.transaction(:attributes_edited.t(:page => page.title), user) do
            page.attributes = parse_attributes
            redirect absolute_path(page) if params[:close] && !page.modified?
            check do |errors|
              errors << :version_conflict.t if !page.new? && page.version.to_s != params[:version]
              errors << :no_changes.t if !page.modified?
            end
            page.save
          end
          flash.info :changes_saved.t
        end
      else
        raise 'Invalid action'
      end
      if params[:close]
        flash.clear
        redirect absolute_path(page)
      else
        render :edit
      end
    end

    private

    def reserved_path?(path)
      self.class.reserved_paths.any? {|pattern| path =~ pattern }
    end
  end
end

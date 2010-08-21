# -*- coding: utf-8 -*-
module Olelo
  # Main class of the application
  class Application
    include Util
    include Routing
    include Templates
    include ApplicationHelper
    include AttributeEditor

    register_attribute :title, :string
    register_attribute :mime,  :string

    patterns :path => Page::PATH_PATTERN
    attr_reader :logger, :user, :theme_links, :timer, :page
    attr_setter :on_error

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

      init_locale
      init_templates
      init_plugins
      init_themes
      init_routes
      invoke_hook(:start)
      run_initializers
    end

    def init_locale
      I18n.locale = Config.locale
      I18n.load(File.join(File.dirname(__FILE__), 'locale.yml'))
    end

    class TemplateLoader
      def context
        Plugin.current.name rescue nil
      end

      def load(name)
        plugin = Plugin.current rescue nil
        fs = []
        fs << DirectoryFS.new(File.dirname(plugin.file)) << InlineFS.new(plugin.file) if plugin
        fs << DirectoryFS.new(Config.views_path)
        UnionFS.new(*fs).read(name)
      end
    end

    def init_templates
      Templates.enable_caching if Config.production?
      Templates.loader = TemplateLoader.new
    end

    def init_plugins
      # Load locales for loaded plugins
      Plugin.after(:load) { I18n.load(File.join(File.dirname(file), 'locale.yml')) }

      # Configure plugin system
      Plugin.logger = logger
      Plugin.disabled = Config.disabled_plugins.to_a
      Plugin.dir = Config.plugins_path

      # Load all plugins
      Plugin.load('*')
    end

    def init_themes
      default = File.basename(File.readlink(File.join(Config.themes_path, 'default')))
      @theme_links = Dir.glob(File.join(Config.themes_path, '*', 'style.css')).map do |file|
        name = File.basename(File.dirname(file))
        path = absolute_path "static/themes/#{name}/style.css?#{File.mtime(file).to_i}"
        %{<link rel="#{name == default ? '' : 'alternate '}stylesheet"
          href="#{escape_html path}" type="text/css" title="#{escape_html name}"/>}.unindent if name != 'default'
      end.compact.join("\n")
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
      render :profile
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
      render :profile
    end

    get '(/:path)/changes/:version' do
      @page = Page.find!(params[:path])
      @version = Version.find!(params[:version])
      @diff = page.diff(nil, @version)
      cache_control :etag => @version, :last_modified => @version.date
      render :changes
    end

    get '(/:path)/history' do
      @page = Page.find!(params[:path])
      @per_page = 30
      @page_nr = params[:page].to_i
      @history = page.history(@page_nr * @per_page)
      @last_page = @page_nr + @history.length / @per_page
      @history = @history[0...@per_page]
      cache_control :etag => page.version, :last_modified => page.version.date
      render :history, :layout => !request.xhr?
    end

    get '/:path/move' do
      @page = Page.find!(params[:path])
      render :move
    end

    get '/:path/delete' do
      @page = Page.find!(params[:path])
      render :delete
    end

    post '/:path/move' do
      on_error :move
      Page.transaction(:page_moved.t(:page => params[:path].cleanpath, :destination => params[:destination].cleanpath), user) do
        @page = Page.find!(params[:path])
        with_hooks(:move, @page, params[:destination]) do
          page.move(params[:destination])
        end
      end
      redirect absolute_path(page)
    end

    get '(/:path)/compare' do
      versions = params[:versions] || []
      redirect absolute_path(versions.size < 2 ? "#{params[:path]}/history" :
                             "#{params[:path]}/compare/#{versions.first}...#{versions.last}")
    end

    get '(/:path)/compare/:versions', :versions => '(?:\w+)\.{2,3}(?:\w+)' do
      @page = Page.find!(params[:path])
      versions = params[:versions].split(/\.{2,3}/)
      @diff = page.diff(versions.first, versions.last)
      render :compare
    end

    get '(/:path)/edit' do
      @page = Page.find!(params[:path])
      flash.warn :warn_binary.t(:page => page.title,
                                :type => "#{page.mime.comment} (#{page.mime})") if page.content =~ /[^[:print:][:space:]]/
      render :edit
    end

    get '(/:path)/new' do
      @page = Page.new(params[:path])
      flash.error :reserved_path.t if reserved_path?(page.path)
      params[:path] = !page.root? && Page.find(page.path) ? page.path + '/' : page.path
      render :edit
    end

    def self.final_routes
      get '(/:path)/version(/:version)|/(:path)' do
        begin
          @page = Page.find!(params[:path], params[:version])
          cache_control :etag => page.version, :last_modified => page.version.date
          @menu_versions = true
          with_hooks(:show) do
            halt render(:show, :locals => {:content => page.try(:content)})
          end
        rescue NotFound
          redirect absolute_path(params[:path].to_s/'new') if params[:version].blank?
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
        on_error :edit
        @page = Page.find(params[:path]) || Page.new(params[:path])

        if action?(:edit) && params[:content]
          with_hooks :save, page do
            raise :empty_comment.t if params[:comment].blank?
            Page.transaction(:page_edited.t(:page => page.title, :comment => params[:comment]), user) do
              # TODO: Implement conflict diffs
              raise :version_conflict.t if !page.new? && page.version.to_s != params[:version]
              page.content = if params[:pos]
                                [page.content[0, params[:pos].to_i].to_s,
                                 params[:content],
                                 page.content[params[:pos].to_i + params[:len].to_i .. -1]].join
                              else
                                params[:content]
                              end
              page.save
            end
            params.delete(:comment)
            flash.info :page_saved.t(:page => page.title)
          end
        elsif action?(:upload) && params[:file]
          with_hooks :save, page do
            Page.transaction(:page_uploaded.t(:page => page.title), user) do
              # TODO: Implement conflict diffs
              raise :version_conflict.t if !page.new? && page.version.to_s != params[:version]
              page.content = params[:file][:tempfile]
              page.save
            end
            flash.info :page_saved.t(:page => page.title)
          end
        elsif action?(:attributes)
          with_hooks :save, page do
            Page.transaction(:attributes_edited.t(:page => page.title), user) do
              # TODO: Implement conflict diffs
              raise :version_conflict.t if !page.new? && page.version.to_s != params[:version]
              update_attributes(page.attributes)
              page.save
            end
            flash.info :page_saved.t(:page => page.title)
          end
        else
          raise 'Invalid action'
        end
        if params[:button] == 'close'
          flash.clear
          redirect absolute_path(page)
        else
          render :edit
        end
      end
    end

    def init_routes
      @reserved_paths = self.class.router.map do |method, router|
        router.map { |name, pattern, keys| [pattern, /#{pattern.source[0..-2]}/] }
      end.flatten
      self.class.final_routes
      invoke_hook(:final_routes)
      self.class.router.each do |method, router|
        logger.debug method
        router.each do |name, pattern, keys|
          logger.debug "#{name} -> #{pattern.source}"
        end
      end if logger.debug?
    end

    private

    def run_initializers
      Dir[File.join(Config.initializers_path, '*.rb')].sort_by do |f|
        File.basename(f)
      end.each do |f|
        logger.debug "Running initializer #{f}"
	instance_eval(File.read(f), f)
      end
    end

    def reserved_path?(path)
      @reserved_paths.any? {|pattern| path =~ pattern }
    end
  end
end

%w(rubygems sinatra/base sinatra/extensions git haml
sass logger cgi wiki/extensions wiki/utils
wiki/object wiki/helper wiki/user wiki/engine wiki/cache wiki/mime wiki/plugin).each { |dep| require dep }

module Wiki
  # Main class of the application
  class App < Sinatra::Application
    include Helper
    include Utils

    # Sinatra options
    set :patterns, :path => PATH_PATTERN, :sha => SHA_PATTERN
    set :haml, :format => :xhtml, :attr_wrapper  => '"', :ugly => true
    set :root, lambda { Config.root }
    set :static, false
    set :raise_errors, false
    set :dump_errors, true
    set :logging, false
    set :methodoverride, false

    def initialize(app = nil, opts = {})
      super(app)

      @logger = opts[:logger] || Logger.new(nil)
      @logger.info self.class.dump_routes

      if File.exists?(Config.git.repository) && File.exists?(Config.git.workspace)
        @logger.info 'Opening repository'
        @repo = Git.open(Config.git.workspace, :repository => Config.git.repository,
                         :index => File.join(Config.git.repository, 'index'), :log => @logger)
      else
        @logger.info 'Initializing repository'
        @repo = Git.init(Config.git.workspace, :repository => Config.git.repository,
                         :index => File.join(Config.git.repository, 'index'), :log => @logger)
        page = Page.new(@repo, Config.main_page)
        page.write('This is the main page of the wiki.', 'Initialize Repository')
        @logger.info 'Repository initialized'
      end

      Plugin.logger = @logger
      Plugin.dir = File.join(App.root, 'plugins')
      Plugin.load_all
    end

    # Executed before each request
    before do
      @logger.debug request.env

      content_type 'application/xhtml+xml', :charset => 'utf-8'

      forbid('No ip given' => !request.ip)
      @user = session[:user] || User.anonymous(request.ip)
      @footer = nil
      @title = ''
    end

    # Handle 404s
    not_found do
      if request.env['wiki.redirect_to_new']
        # Redirect to create new page if flag is set
        redirect(params[:sha] ? params[:path].urlpath : (params[:path]/'new').urlpath)
      else
        @error = request.env['sinatra.error'] || Sinatra::NotFound.new
        haml :error
      end
    end

    # Show wiki error page
    error do
      @error = request.env['sinatra.error']
      @logger.error @error
      haml :error
    end

    get '/sys/fragments/user' do
      haml :'fragments/user', :layout => false
    end

    get '/sys/fragments/sidebar' do
      if page = Page.find(@repo, 'Sidebar')
        engine = Engine.find(page)
        if engine.layout?
          #cache_control :etag => page.commit.sha, :last_modified => page.latest_commit.committer_date
          cache_control :max_age => 120
          engine.render(page)
        else
          '<span class="error">No engine found for Sidebar</span>'
        end
      else
        '<a href="/Sidebar/new">Create Sidebar</a>'
      end
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
        session[:user] = User.authenticate(params[:user], params[:password])
        redirect '/'
      rescue MessageError => error
        message :error, error.message
        haml :login
      end
    end

    post '/signup' do
      begin
        session[:user] = User.create(params[:user], params[:password],
                                     params[:confirm], params[:email])
        redirect '/'
      rescue MessageError => error
        message :error, error.message
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
          @user.transaction do |user|
            user.change_password(params[:oldpassword], params[:password], params[:confirm]) if !params[:password].blank?
            user.email = params[:email]
          end
          message :info, 'Changes saved'
          session[:user] = @user
        rescue MessageError => error
          message :error, error.message
        end
      end
      haml :profile
    end

    get '/style.css' do
      begin
        # Try to use wiki version
        params[:output] = 'css'
        params[:path] = 'style.sass'
        show
      rescue Object::NotFound
        cache_control :max_age => 120
        # Fallback to default style
        content_type 'text/css', :charset => 'utf-8'
        sass :style, :sass => {:style => :compact}
      end
    end

    get '/commit/:sha' do
      cache_control :etag => params[:sha], :validate_only => true
      @commit = @repo.gcommit(params[:sha])
      cache_control :etag => @commit.sha, :last_modified => @commit.committer_date
      @diff = @repo.diff(@commit.parent, @commit.sha)
      haml :commit
    end

    get '/?:path?/archive' do
      @tree = Tree.find!(@repo, params[:path])
      cache_control :etag => @tree.sha, :last_modified => @tree.commit.committer_date
      content_type 'application/x-tar-gz'
      attachment "#{@tree.safe_name}.tar.gz"
      archive = @tree.archive
      begin
        # See send_file
        response['Content-Length'] ||= File.stat(archive).size.to_s
        halt StaticFile.open(archive, 'rb')
      rescue Errno::ENOENT
        not_found
      end
    end

    get '/?:path?/history' do
      @object = Object.find!(@repo, params[:path])
      cache_control :etag => @object.sha, :last_modified => @object.commit.committer_date
      haml :history
    end

    get '/?:path?/diff' do
      cache_control :static => true
      @object = Object.find!(@repo, params[:path])
      @diff = @object.diff(params[:from], params[:to])
      haml :diff
    end

    get '/:path/edit', '/:path/append', '/:path/upload' do
      begin
        @page = Page.find!(@repo, params[:path])
        haml :edit
      rescue Object::NotFound
        pass if action? :upload # Pass to next handler because /upload is used twice
        raise
      end
    end

    get '/new', '/upload', '/:path/new', '/:path/upload' do
      begin
        # Redirect to edit for existing pages
        if !params[:path].blank? && Object.find(@repo, params[:path])
          redirect (params[:path]/'edit').urlpath
        end
        @page = Page.new(@repo, params[:path])
        boilerplate @page
        check_name_clash(params[:path])
      rescue MessageError => error
        message :error, error.message
      end
      haml :new
    end

    get '/:sha', '/:path/:sha', '/:path' do
      begin
        pass if name_clash?(params[:path])
        show
      rescue Object::NotFound
        request.env['wiki.redirect_to_new'] = true
        pass
      end
    end

    # Edit form sends put requests
    put '/:path' do
      @page = Page.find!(@repo, params[:path])
      begin
        if action?(:upload) && params[:file]
          @page.write(params[:file][:tempfile].read, 'File uploaded', @user.author)
          show(@page)
        else
          if action?(:append) && params[:appendix] && @page.mime.text?
            @page.content = @page.content + "\n" + params[:appendix]
          elsif action?(:edit) && params[:content]
            @page.content = params[:content]
          else
            redirect @page.path.urlpath/'edit'
          end

          if @page.mime.text? && params[:preview]
            message :error, 'Commit message is empty' if params[:message].empty?
            engine = Engine.find(@page)
            @preview_content = engine.render(@page) if engine.layout?
            haml :edit
          else
            @page.save(params[:message], @user.author)
            show(@page)
          end
        end
      rescue MessageError => error
        message :error, error.message
        haml :edit
      end
    end

    # New form sends post request
    post '/', '/:path' do
      begin
        @page = Page.new(@repo, params[:path])
        if action?(:upload) && params[:file]
          check_name_clash(params[:path])
          @page.write(params[:file][:tempfile].read, "File #{@page.path} uploaded", @user.author)
          redirect params[:path].urlpath
        elsif action?(:new)
          @page.content = params[:content]
          if @page.mime.text? && params[:preview]
            message :error, 'Commit message is empty' if params[:message].empty?
            engine = Engine.find(@page)
            @preview_content = engine.render(@page) if engine.layout?
            haml :new
          else
            check_name_clash(params[:path])
            @page.save(params[:message], @user.author)
            redirect params[:path].urlpath
          end
        else
          redirect '/new'
        end
      rescue MessageError => error
        message :error, error.message
        haml :new
      end
    end

    private

    def name_clash?(path)
      path = path.to_s.urlpath
      patterns = self.class.routes.values.inject([], &:+).map {|x| x[0] }.uniq

      # Remove overly general patterns
      patterns.delete(%r{.*[^\/]$}) # Sinatra static files
      patterns.delete(%r{^/(#{PATH_PATTERN})$}) # Path
      patterns.delete(%r{^/(#{PATH_PATTERN})/(#{SHA_PATTERN})$}) # Path with unstrict sha
      patterns.delete(%r{^/(#{SHA_PATTERN})$}) # Root with unstrict sha

      # Add pattern to ensure availability of strict sha urls
      # Shortcut sha urls (e.g /Beef) can be overridden
      patterns << %r{^/(#{STRICT_SHA_PATTERN})$}
      patterns << %r{^/(#{PATH_PATTERN})/(#{STRICT_SHA_PATTERN})$}

      patterns.any? {|pattern| pattern =~ path }
    end

    def check_name_clash(path)
      forbid('Path is not allowed' => name_clash?(path))
    end

    # Show page or tree
    def show(object = nil)
      cache_control :etag => params[:sha], :validate_only => true
      object = Object.find!(@repo, params[:path], params[:sha]) if !object || object.new?

      if object.tree?
        root = Tree.find!(@repo, '/', params[:sha])
        cache_control :etag => root.latest_commit.sha, :last_modified => root.latest_commit.committer_date

        @tree = object
        @children = walk_tree(root, params[:path].to_s.cleanpath.split('/'), 0)
        haml :tree
      else
        cache_control :etag => object.latest_commit.sha, :last_modified => object.latest_commit.committer_date

        @page = object
        engine = Engine.find(@page, params[:output])
        @content = engine.render(@page, params)
        if engine.layout?
          haml :page
        else
          content_type engine.mime(@page).to_s
          @content
        end
      end
    end

    def walk_tree(tree, path, level)
      result = []
      tree.children.each do |child|
        open = child.tree? && (child.path == path[0..level].join('/'))
        result << [level, child, open]
        result += walk_tree(child, path, level + 1) if open
      end
      result
    end

    # Boilerplate for new pages
    def boilerplate(page)
      if page.path == 'style.sass'
        page.content = lookup_template :sass, :style
      end
    end

  end
end

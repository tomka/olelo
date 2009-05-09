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
      Plugin.dir = File.join(Config.root, 'plugins')
      Plugin.load('*')
      Plugin.start

      @logger.info self.class.dump_routes
    end

    # Executed before each request
    add_hook(:before_routing) do
      start_timer
      @logger.debug request.env

      content_type 'application/xhtml+xml', :charset => 'utf-8'

      @user = session[:user] || User.anonymous(request)
    end

    # Handle 404s
    add_hook(NotFound) do |ex|
      if request.env['wiki.redirect_to_new']
        # Redirect to create new page if flag is set
        redirect(params[:sha] ? params[:path].urlpath : (params[:path]/'new').urlpath)
      else
        @error = ex
        haml :error
      end
    end

    # Show wiki error page
    add_hook(Exception) do |ex|
      @error = ex
      @logger.error @error
      haml :error
    end

    get '/sys/fragments/user' do
      haml :user, :layout => false
    end

    get '/sys/fragments/sidebar' do
      if page = Page.find(@repo, 'Sidebar')
        engine = Engine.find!(page)
        if engine.layout?
          #cache_control :etag => page.commit.sha, :last_modified => page.latest_commit.date
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
      rescue StandardError => error
        message :error, error
        haml :login
      end
    end

    post '/signup' do
      begin
        session[:user] = User.create(params[:user], params[:password],
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
          message :info, 'Changes saved'
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
        raise if !%w(screen print reset).include?(params[:style])
        # Fallback to default style
        cache_control :max_age => 120
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
        @resource = Resource.new(@repo, params[:path])
        boilerplate @resource
        forbid('Path is not allowed' => name_clash?(params[:path]))
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
        if action?(:upload) && params[:file]
          @resource.write(params[:file][:tempfile], 'File uploaded', @user.author)
        elsif action?(:edit) && params[:content]
          preview(:edit, params[:content])
          content = if params[:pos]
                      pos = [[0, params[:pos].to_i].max, @resource.content.size].min
                      len = params[:len] ? [0, params[:len].to_i].max : @resource.content.size - params[:len]
                      @resource.content[0,pos].to_s + params[:content] + @resource.content[pos+len..-1].to_s
                    else
                      params[:content]
                    end
          @resource.write(content, params[:message], @user.author)
        else
          redirect((@resource.path/'edit').urlpath)
        end
        invoke_hook :page_saved, @resource
        redirect @resource.path.urlpath
      rescue StandardError => error
        message :error, error
        haml :edit
      end
    end

    # New form sends post request
    post '/', '/:path' do
      begin
        @resource = Page.new(@repo, params[:path])
        if action?(:upload) && params[:file]
          forbid('Path is not allowed' => name_clash?(@resource.path))
          @resource.write(params[:file][:tempfile], "File #{@resource.path} uploaded", @user.author)
        elsif action?(:new)
          preview(:new, params[:content])
          forbid('Path is not allowed' => name_clash?(@resource.path))
          @resource.write(params[:content], params[:message], @user.author)
        else
          redirect '/new'
        end
        invoke_hook :page_saved, @resource
        redirect @resource.path.urlpath
      rescue StandardError => error
        message :error, error
        haml :new
      end
    end

    private

    def preview(template, content)
      if params[:preview]
        message(:error, 'Commit message is empty') if params[:message].empty?
        message(:error, 'Path is not allowed') if name_clash?(@resource.path)
        @resource.preview_content = content
        if @resource.mime.text?
          engine = Engine.find!(@resource)
          @preview = engine.render(@resource) if engine.layout?
        end
        halt haml(template)
      end
    end

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

    # Show page or tree
    def show
      cache_control :etag => params[:sha], :validate_only => true
      @resource = Resource.find!(@repo, params[:path], params[:sha])

      if @resource.tree?
        root = Tree.find!(@repo, '/', params[:sha])
        cache_control :etag => root.commit.sha, :last_modified => root.commit.date

        @children = walk_tree(root, params[:path].to_s.cleanpath.split('/'), 0)
        haml :tree
      else
        cache_control :etag => @resource.latest_commit.sha, :last_modified => @resource.latest_commit.date

        engine = Engine.find!(@resource, params[:output])
        @content = engine.render(@resource, params)
        if engine.layout?
          haml :page
        else
          content_type engine.mime(@resource).to_s
          @content
        end
      end
    end

    # Walk tree and return array with level counter
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
      if page.path =~ /^\w+\.sass$/
        name = File.join(Config.root, 'views', 'style', $&)
        page.content = File.read(name) if File.file?(name)
      end
    end

  end
end

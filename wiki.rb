%w(
rubygems
sinatra_ext
git
haml
sass
rubypants
mime/types
logger
open3
yaml/store
digest
cgi).each { |dep| require dep }

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class Symbol
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end

class Time
  def format
    strftime('%d. %h %Y %H:%M')
  end
end

class String
  def last_lines(max)
    lines = split("\n")
    if lines.length <= max
      self
    else
      lines[-max..-1].join("\n")
    end
  end

  def ends_with?(str)
    str = str.to_str
    tail = self[-str.length, str.length]
    tail == str      
  end

  def cleanpath
    names = split('/')
    # /root maps to /
    names.delete_at(0) if names[0] == 'root'
    i = 0
    while i < names.length
      case names[i]
      when '..'
        names.delete_at(i)
        if i>0
          names.delete_at(i-1)
          i-=1
        end
      when '.'
        names.delete_at(i)
      when ''
        names.delete_at(i)
      else
        i+=1
      end
    end
    names.join('/')
  end

  def urlpath
    path = cleanpath
    path == '' ? '/root' : '/' + path
  end

  def truncate(max, omission = '...')
    (length > max ? self[0...max-3] + omission : self)
  end

  def /(name)
    (self + '/' + name).cleanpath
  end
end

module Highlighter
  def self.text(text, format)
    Open3.popen3("pygmentize -O linenos=table -f html -l #{format}") { |stdin, stdout, stderr|
      stdin << text
      stdin.close
      stdout.read
    }
  end

  def self.file(content, name)
    lexer = find_lexer(name)
    lexer ? text(content, lexer) : CGI::escapHTML(content)
  end

  def self.supports?(filename)
    !!find_lexer(filename)
  end

  private

  def self.lexer_mapping
    mapping = {}
    lexer = ''  
    output = `pygmentize -L lexer`
    output.split("\n").each do |line|
      if line =~ /^\* ([^:]+):$/
        lexer = $1.split(', ').first
      elsif line =~ /^   [^(]+ \(filenames ([^)]+)/
        $1.split(', ').each {|s| mapping[s] = lexer }
      end
    end
    mapping
  end

  def self.find_lexer(name)
    @mapping ||= lexer_mapping
    pattern = @mapping.keys.find {|pattern| File.fnmatch(pattern, name)}
    pattern ? @mapping[pattern] : nil
  end
end

module Wiki

  module Validation
    class Failed < ArgumentError; end

    def self.validate(conds)
      failed = conds.keys.select {|key| !conds[key]}
      raise Failed.new(failed) if !failed.empty?
    end
  end

  class Object
    class NotFound < Sinatra::NotFound
      def initialize(path)
        super('#{path} not found', path)
      end
    end

    attr_reader :repo, :path, :commit, :object

    def self.find(repo, path, sha = nil)
      path = path.cleanpath
      commit = sha ? repo.gcommit(sha) : repo.log(1).path(path).first
      create(repo, path, commit, Object.find_in_repo(repo, path, commit))
    end

    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound.new(path))
    end

    def exists?
      !!@object
    end

    def head?(commit = nil)
      commit ||= @commit
      commit = @repo.gcommit(commit) if commit.is_a? String
      head_commit.committer_date <= commit.committer_date
    end

    def history
      @history ||= @repo.log.path(path).to_a
    end

    def head_commit
      history.first
    end

    def prev_commit
      @prev_commit ||= @repo.log(2).object(@commit.sha).path(@path).to_a[1]
    end

    def next_commit
      h = history
      h.each_index { |i| return (i == 0 ? nil : h[i - 1]) if h[i].committer_date <= @commit.committer_date }
      h.last # FIXME. Does not work correctly if history is too short
    end
      
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    def safe_name
      n = name
      n = 'root' if n.blank?
      n.gsub(/[^\w.\-_]/, '_')
    end

    def diff(to)
      @repo.diff(@commit.sha, to).path(path)
    end

    def initialize(repo, path, commit = nil, object = nil)
      @repo = repo
      @path = path.cleanpath
      @commit = commit
      @object = object
    end

    private

    def self.create(repo, path, commit, object)
      if object
        return Page.new(repo, path, commit, object) if object.blob?
        return Tree.new(repo, path, commit, object) if object.tree?
      end
      nil
    end

    def self.find_in_repo(repo, path, commit)
      begin
        if commit
          object = if path.blank?
                     commit.gtree
                   elsif path =~ /\//
                     path.split('/').inject(commit.gtree) { |t, x| t.children[x] } rescue nil
                   else
                     commit.gtree.children[path]
                   end
          return object if object
        end
        nil
      rescue
        nil
      end
    end

  end

  class Page < Object
    def content
      @object ? @object.contents : nil
    end
    
    def update(new_content, message, author = nil)
      return if new_content == content
      repo.chdir {
        FileUtils.makedirs File.dirname(@path)
        File.open(@path, 'w') {|f| f << new_content }
      }
      repo.add(@path)
      repo.commit(message.blank? ? '(Empty commit message)' : message, :author => author)
      @prev_commit = @history = nil
      @commit = head_commit
      @object = Object.find_in_repo(@repo, @path, @commit) || raise(NotFound.new(path))
    end

    def extension
      path =~ /\.([^.]+)$/
      $1
    end

    def pretty_name
      name.gsub(/\.([^.]+)$/, '')
    end

    def mime_type
      @mime_types ||= MIME::Types.of(path)
      @mime_types.empty? ? nil : @mime_types.first
    end
  end
  
  class Tree < Object
    def children
      @object.children.to_a.map {|x| Object.create(repo, path/x[0], commit, x[1]) }.compact
    end

    def pretty_name
      '&radic;&macr; Root'/path
    end
  end

  module Helper
    def object_path(object, commit = nil, output = nil)
      commit ||= object.commit
      sha = commit.is_a?(String) ? commit : commit.sha      
      (object.head?(commit) ? object.path : object.path/sha).urlpath + (output ? "?output=#{output}" : '')
    end

    def child_path(tree, child)
      (child.path/(tree.head? ? '' : tree.commit.sha)).urlpath
    end

    def parent_path(tree)
      (tree.path/'..'/(tree.head? ? '' : tree.commit.sha)).urlpath
    end

    def action_path(object, action)
      (object.path/action.to_s).urlpath
    end

    def image(alt, name)
      "<img src=\"/images/#{name}.png\" alt=\"#{CGI::escapeHTML alt}\"/>"
    end

    def tab_selected(action)
      action?(action) ? {:class=>'ui-tabs-selected'} : {}
    end

    def menu
      @menu ||= []
      haml :menu, :layout => false, :locals => { :enabled => @menu.is_a?(Array) ? @menu : [@menu] }
    end

    def sidebar
      haml :sidebar, :layout => false
    end

    def show_messages
      if session[:messages]
        out = "<ul>\n"
        session[:messages].each do |msg|
          out += "  <li class=\"#{msg[0]}\">#{msg[1]}</li>\n"
        end
        out += "</ul>\n"
        session[:messages] = nil
        return out
      end
      ''
    end

    def message(level, msg)
      session[:messages] ||= []
      session[:messages] << [level, msg]
    end

    def action?(name)
      request.path_info.ends_with? '/' + name.to_s
    end
  end

  class Engine
    include Helper

    class NotAvailable < ArgumentError
      def initialize(name)
        super("Output engine #{name} is not available")
      end
    end
    
    attr_reader :name
    def layout?; @layout; end
    
    def initialize(name, layout)
      @name = name
      @layout = layout
    end
    
    def self.create(name, layout, &block)
      Class.new(Engine, &block).new(name, layout)
    end

    def self.find(page, name = nil)
      engine = ENGINES.find { |e| (name.blank? || e.name == name.to_sym) && e.accepts(page) }
      return engine if engine
      raise NotAvailable.new(name)
    end
    
    def self.method_missing(sym, &block)
      define_method sym, &block
    end
    
    accepts {|page| false }
    output  {|page| '' }
    mime    {|page| 'text/plain' }
    
    ENGINES =
      [
       Engine.create(:creole, true) {
         accepts {|page| page.extension =~ /^(text|creole)$/ }
         output  {|page|
           require 'creole'
           creole = Creole::CreoleParser.new
           class << creole
             def make_image_link(url)
               url + '?output=raw'
             end
             def make_link(url)
               escape_url(url).urlpath
             end
           end
           RubyPants.new(creole.parse(page.content)).to_html
         }
       },
       Engine.create(:markdown, true) {
         accepts {|page| page.extension =~ /^(markdown|md|mdown|mkdn|mdown)$/  }
         output  {|page|
           require 'rdiscount'
           RubyPants.new(RDiscount.new(page.content).to_html).to_html
         }
       },
       Engine.create(:textile, true) {
         accepts {|page| page.extension == 'textile'  }
         output  {|page|
           require 'redcloth'
           RubyPants.new(RedCloth.new(page.content).to_html).to_html
         }
       },
       Engine.create(:code, true) {
         accepts {|page| Highlighter.supports?(page.name) }
         output  {|page| Highlighter.file(page.content, page.name) }
       },
       Engine.create(:image, true) {
         accepts {|page| page.mime_type && page.mime_type.media_type == 'image' }
         output  {|page| "<img src=\"#{object_path(page, nil, 'raw')}\"/>" }
       },
       Engine.create(:html, true) {
         accepts {|page| page.mime_type && page.mime_type.ascii? }
         output  {|page| '<pre>' + CGI::escapeHTML(page.content) + '</pre>' }
         mime    {|page| page.mime_type }
       },
       Engine.create(:download, true) {
         accepts {|page| true }
         output  {|page| "<a href=\"#{object_path(page, nil, 'raw')}\">Download</a>" }
       },
       Engine.create(:raw, false) {
         accepts {|page| true }
         output  {|page| page.content }
         mime    {|page| page.mime_type ? page.mime_type : 'application/octet-stream' }
       },
       Engine.create(:css, false) {
         accepts {|page| page.extension == 'sass' }
         output  {|page| Sass::Engine.new(page.content).render }
         mime    {|page| 'text/css' }
       },
      ]
  end

  class User
    attr_accessor :email
    attr_reader :name, :password

    def anonymous?; @anonymous; end

    def password=(pw)
      @password = User.crypt(pw)
    end

    def author
      "#{@name} <#{@email}>"
    end

    def save
      Validation.validate(
        'E-Mail is invalid' => (@email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i),
        'Name is invalid'   => (@name =~ /[\w.\-+_]+/),
        'Password is empty' => (!@password.blank?)
      )
      User.transaction(false) {|store| store[name] = self }
    end

    def self.anonymous(ip)
      User.new(ip, nil, "anonymous@#{ip}", true)
    end

    def self.authenticate(name, password)
      user = find(name)
      Validation.validate('Wrong username or password' => (user && user.password == User.crypt(password)))
      user
    end

    def self.find(name)
      transaction(true) {|store|
        return store[name]
      }
    end

    def self.create(name, password, email)
      Validation.validate('User already exists' => !find(name))
      user = User.new(name, password, email, false)
      user.save
      user
    end

    def to_yaml_properties
      %w(@name @email @password)
    end

    private

    def initialize(name, password, email, anonymous)
      @name = name
      @email = email
      @anonymous = anonymous
      @password = User.crypt(password)
    end

    def self.crypt(s)
      s.blank? ? s : Digest::SHA256.hexdigest(s)
    end

    def self.transaction(read_only, &block)
      store.transaction(read_only, &block)
    end

    def self.store
      @store ||= YAML::Store.new(App.config['users_store'])
    end
  end

  class App < Sinatra::Base
    PATH_PATTERN = /[\w.+\-_\/](?:[\w.+\-_\/ ]+[\w.+\-_\/])?/
    pattern :path, PATH_PATTERN
    pattern :sha,  /[A-Fa-f0-9]{40}/

    set :haml, { :format => :xhtml, :attr_wrapper  => '"' }
    set :methodoverride, true
    set :static, true
    set :app_file, 'wiki.rb'
    set :raise_errors, false
    set :dump_errors, true
    use Rack::Session::Pool

    include Helper

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = Logger.const_get(App.config['loglevel'])
      if File.exists?(App.config['repository']) && File.exists?(App.config['workspace'])
        @repo = Git.open(App.config['workspace'], :repository => App.config['repository'],
                         :index => File.join(App.config['repository'], 'index'), :log => @logger)
      else
        @repo = Git.init(App.config['workspace'], :repository => App.config['repository'],
                         :index => File.join(App.config['repository'], 'index'), :log => @logger)
        page = Page.new(@repo, 'init.txt')
        page.update('This file is used to initialize the repository. It can be deleted.', 'Initialize Repository')
      end      
    end

    def show
      @object = Object.find!(@repo, params[:path], params[:sha]) if !@object || !@object.exists?
      @feed = (@object.path/'changelog.rss').urlpath
      if @object.tree?
        haml :tree
      else
        engine = Engine.find(@object, params[:output])
        @content = engine.output(@object)
        if engine.layout?
          haml :page
        else
          content_type engine.mime(@object).to_s
          @content
        end
      end
    end

    before do
      # Sinatra does not unescape before pattern matching
      # Paths with spaces won't be recognized
      request.path_info = CGI::unescape(request.path_info)
      @logger.debug request.env
      content_type 'application/xhtml+xml', :charset => 'utf-8'
      @user = session[:user] || User.anonymous(request.ip)
    end

    not_found do
      redirect((params[:path]/'new').urlpath) if params[:path]
      @error = request.env['sinatra.error']
      haml :error
    end

    error Validation::Failed do
      request.env['sinatra.error'].message.each do |msg|
        message :error, msg
      end
      redirect(@error_path || request.path_info)
    end

    error do
      @error = request.env['sinatra.error']
      haml :error
    end

    get '/' do
      redirect '/home.text'
    end

    get '/login', '/signup' do
      haml :login
    end

    post '/login' do
      session[:user] = User.authenticate(params[:user], params[:password])
      redirect '/'
    end

    post '/signup' do
      session[:user] = User.create(params[:user], params[:password], params[:email])
      redirect '/'
    end

    get '/logout' do
      session[:user] = @user = nil
      redirect '/'
    end

    get '/profile' do
      haml :profile
    end

    get '/search' do
      @matches = @repo.grep(params[:pattern])
      haml :search
    end

    get '/style.css' do
      begin
        # Try to use wiki version
        params[:output] = 'css'
        params[:path] = 'style.sass'
        show
      rescue Object::NotFound
        # Fallback to default style
        content_type 'text/css', :charset => 'utf-8'
        sass :style
      end
    end
    
    get '/archive', '/:path/archive' do
      params[:path] ||= ''
      @object = Object.find!(@repo, params[:path])
      content_type 'application/x-tar-gz'
      attachment "#{@object.safe_name}.tar.gz"
      archive = @repo.archive(@object.object.sha, nil, :format => 'tgz', :prefix => "#{@object.safe_name}/")
      File.open(archive).read
    end

    get '/history', '/:path/history' do
      params[:path] ||= ''
      @object = Object.find!(@repo, params[:path])      
      haml :history
    end

    get '/changelog.rss', '/:path/changelog.rss' do
      params[:path] ||= ''
      object = Object.find!(@repo, params[:path])
      require 'rss/maker'
      content_type 'application/rss+xml', :charset => 'utf-8'
      content = RSS::Maker.make('2.0') do |rss|
        rss.channel.title = App.config['title']
        rss.channel.link = request.scheme + '://' +  (request.host + ':' + request.port.to_s)
        rss.channel.description = App.config['title'] + ' Changelog'
        rss.items.do_sort = true
        object.history.each do |commit|
          i = rss.items.new_item
          i.title = commit.message
          i.link = request.scheme + '://' + (request.host + ':' + request.port.to_s)/object.path/commit.sha
          i.date = commit.committer.date
        end
      end
      content.to_s
    end

    get '/diff', '/:path/diff' do
      params[:path] ||= ''
      @from = params[:from]
      @to = params[:to]
      @object = Object.find!(@repo, params[:path], @from)
      @diff = @object.diff(@to)
      haml :diff
    end

    get '/new', '/upload', '/:path/new', '/:path/upload' do
      @path = params[:path] || ''
      if !@path.blank? && Object.find(@repo, @path)
        # Pass to upload for existing pages
        pass if action?(:upload)
        # Redirect to page if action == new
        redirect(params[:path].urlpath)
      end
      haml :new
    end

    get '/:path/edit', '/:path/append', '/:path/upload' do
      @object = Object.find!(@repo, params[:path])
      if @object.page?
        haml :edit
      else
        redirect(@object.path.urlpath)
      end
    end

    get '/:sha', '/:path/:sha', '/:path' do
      params[:path] ||= ''
      show
    end

    put '/:path' do
      @object = Object.find!(@repo, params[:path])
      if @object.page?
        if params[:file]
          @object.update(params[:file][:tempfile].read, 'File uploaded', @user.author)
        elsif params[:appendix]
          @object.update(@object.content + "\n" + params[:appendix], params[:message], @user.author)
        else
          @object.update(params[:content], params[:message], @user.author)
        end
      end
      show
    end

    post '/', '/:path' do
      @error_path = params[:file] ? '/upload' : '/new'
      Validation.validate('Invalid path' => params[:path] =~ /^#{PATH_PATTERN.source}$/)
      @object = Page.new(@repo, params[:path])
      if params[:file]
        @object.update(params[:file][:tempfile].read, 'File uploaded', @user.author)
      else
        @object.update(params[:content], params[:message], @user.author)
      end
      redirect params[:path].urlpath
    end
  end
end

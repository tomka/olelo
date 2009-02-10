%w(rubygems sinatra_ext git haml
sass mime logger open3
yaml/store digest cgi).each { |dep| require dep }

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

class String
  def pluralize(count, plural)
    "#{count || 0} " + (count.to_s == '1' ? self : plural)
  end

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
    names = split('/').reject(&:blank?)
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
      else
        i+=1
      end
    end
    names.join('/')
  end

  def urlpath
    path = cleanpath
    path.blank? ? '/root' : '/' + path
  end

  def truncate(max, omission = '...')
    (length > max ? self[0...max-3] + omission : self)
  end

  def /(name)
    (self + '/' + name).cleanpath
  end
end

module Highlighter
  `pygmentize -V 2>&1 > /dev/null`
  @installed = $? == 0

  def self.installed?
    @installed
  end

  def self.text(text, format)
    return CGI::escapeHTML(text) if !installed? 
    content = Open3.popen3("pygmentize -O linenos=table -f html -l '#{format}'") { |stdin, stdout, stderr|
      stdin << text
      stdin.close
      stdout.read
    }
    content.blank? ? CGI::escapeHTML(text) : content
  end

  def self.file(content, name)
    lexer = find_lexer(name)
    lexer ? text(content, lexer) : CGI::escapeHTML(content)
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
    pattern && @mapping[pattern]
  end
end

class MessageError < StandardError; end

def forbid(conds)
  failed = conds.keys.select {|key| conds[key]}
  raise MessageError.new(failed) if !failed.empty?
end

def safe_require(name)
  require(name)
  true
rescue LoadError
  false
end

def safe_require_all(name)
  Dir.glob(File.join(name, '**/*.rb')).each { |file| require file }
end

class Mime
  attr_reader :type, :mediatype, :subtype
  
  def self.add(type, extensions, parents)
    MIME_TYPES[type] = [extensions, parents]
    extensions.each do |ext|
      MIME_EXTENSIONS[ext] = type
    end
  end
  
  def text?
    child_of? 'text/plain'
  end
  
  def child_of?(parent)
    Mime.child?(type, parent)
  end
  
  def extensions
    MIME_TYPES.include?(type) ? MIME_TYPES[type][0] : []
  end
  
  def self.by_extension(ext)
    mime = MIME_EXTENSIONS[ext.downcase]
    mime ? new(mime) : nil
  end
  
  def to_s
    type
  end

  def ==(x)
    type == x.to_s
  end
  
  def initialize(type)
    @type      = type
    @mediatype = @type.split('/')[0]
    @subtype   = @type.split('/')[1]
  end
    
  private

  def self.child?(child, parent)
    return true if child == parent
    MIME_TYPES.include?(child) ? MIME_TYPES[child][1].any? {|p| child?(p, parent) } : false
  end
end

class Entry
  class ConcurrentModificationError < RuntimeError; end

  def self.store=(store_file)
    @store = YAML::Store.new(store_file)
  end    

  attr_reader :version, :name

  def self.transient(attr)
    transient_variables << '@' + attr.to_s
  end

  def self.transient_variables
    @transient ||= []
  end

  def initialize(name)
    @version = 0
    @name = name
  end

  def transaction(&block)
    copy = dup
    block.call(copy)
    copy.save
    instance_variables.each do |name|
      instance_variable_set(name, copy.instance_variable_get(name))
    end
  end

  def save
    Entry.store.transaction(false) do |s|
      bucket = self.class.name
      raise ConcurrentModificationError if version > 0 && (!s[bucket] || s[bucket][name].version > version)
      @version += 1
      s[bucket] ||= {}
      s[bucket][name] = self
    end
    self
  end

  def remove
    Entry.store.transaction(false) do |s|
      bucket = self.class.name
      raise ConcurrentModificationError if !s[bucket] || s[bucket][name].version > version
      s[bucket].delete(name)
      s.delete(bucket) if s[bucket].empty?
    end
    @version = 0
    self
  end

  def self.find(name)
    Entry.store.transaction(true) do |s|
      return s[self.name] ? s[self.name][name] : nil
    end
  end

  def to_yaml_properties
    super.reject {|attr| self.class.transient_variables.include?(attr)}
  end

  private

  def self.store
    @store
  end
end

module Wiki
  PATH_PATTERN = '[\w.+\-_\/](?:[\w.+\-_\/ ]+[\w.+\-_\/])?'
  SHA_PATTERN = '[A-Fa-f0-9]{40}'

  class Object
    class NotFound < Sinatra::NotFound
      def initialize(path)
        super("#{path} not found", path)
      end
    end

    attr_reader :repo, :path, :commit, :object

    def self.find(repo, path, sha = nil)
      path ||= ''
      path = path.cleanpath
      forbid_invalid_path(path)
      commit = sha ? repo.gcommit(sha) : repo.log(1).path(path).first rescue nil
      if commit
        object = Object.git_find(repo, path, commit)
        return Page.new(repo, path, commit, object) if object.blob?
        return Tree.new(repo, path, commit, object) if object.tree?
      end
      nil
    end

    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound.new(path))
    end

    def new?
      !@object
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

    def pretty_name
      name.gsub(/\.([^.]+)$/, '')
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
      path ||= ''
      path = path.cleanpath
      Object.forbid_invalid_path(path)
      @repo = repo
      @path = path.cleanpath
      @commit = commit
      @object = object
    end

    protected

    def self.forbid_invalid_path(path)
      forbid('Invalid path' => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
    end

    def self.git_find(repo, path, commit)
      return nil if !commit
      if path.blank?
        return commit.gtree rescue nil
      elsif path =~ /\//
        return path.split('/').inject(commit.gtree) { |t, x| t.children[x] } rescue nil
      else
        return commit.gtree.children[path] rescue nil
      end
    end

  end

  class Page < Object
    attr_writer :content

    def initialize(repo, path, commit = nil, object = nil)
      super(repo, path, commit, object)
      @content = nil
    end

    def self.find(repo, path, sha = nil)
      object = super(repo, path, sha)
      object && object.page? ? object : nil
    end

    def content
      @content || current_content
    end

    def current_content
      @object ? @object.contents : nil
    end

    def write(content, message, author = nil)
      @content = content
      save(message, author)
    end    

    def save(message, author = nil)
      return if @content == current_content

      forbid('No content'   => @content.blank?,
             'Object already exists' => new? && Object.find(@repo, @path))

      repo.chdir {
        FileUtils.makedirs File.dirname(@path)
        File.open(@path, 'w') {|f| f << @content }
      }
      repo.add(@path)
      repo.commit(message.blank? ? '(Empty commit message)' : message, :author => author)

      @content = nil
      @prev_commit = @history = nil
      @commit = head_commit
      @object = Object.git_find(@repo, @path, @commit) || raise(NotFound.new(path))
    end

    def extension
      path =~ /\.([^.]+)$/
      $1 || ''
    end

    def mime
      @mime ||= Mime.by_extension(extension) || Mime.new(App.config['default_mime'])
    end
  end
  
  class Tree < Object
    def initialize(repo, path, commit = nil, object = nil)
      super(repo, path, commit, object)
      @children = nil
    end
    
    def self.find(repo, path, sha = nil)
      object = super(repo, path, sha)
      object && object.tree? ? object : nil
    end

    def children
      @children ||= @object.trees.to_a.map {|x| Tree.new(repo, path/x[0], commit, x[1])}.sort {|a,b| a.name <=> b.name } +
                    @object.blobs.to_a.map {|x| Page.new(repo, path/x[0], commit, x[1])}.sort {|a,b| a.name <=> b.name }
    end

    def pretty_name
      '&radic;&macr; Root'/path
    end
  end

  module Helper
    def date(t)
      "<span class=\"date seconds=#{t.to_i}\">#{t.strftime('%d %h %Y %H:%M')}</span>"
    end

    def breadcrumbs(path)
      links = ['<a href="/root">&radic;&macr; Root</a>']
      path.split('/').inject('') {|parent,elem|        
        links << "<a href=\"#{(parent/elem).urlpath}\">#{elem}</a>"
        parent/elem
      }
      
      result = []
      links.each_with_index {|link,i|
        result << "<li class=\"breadcrumb#{i==0 ? ' first' : ''}#{i==links.size-1 ? ' last' : ''}\">#{link}</li>"
      }
      result.join('<li class="breadcrumb">/</li>')
    end

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
      if @messages
        out = "<ul>\n"
        @messages.each do |msg|
          out += "  <li class=\"#{msg[0]}\">#{msg[1]}</li>\n"
        end
        out += "</ul>\n"
        return out
      end
      ''
    end

    def message(level, messages)
      @messages ||= []
      messages = [messages] if !messages.is_a?(Array)
      messages.each do |msg|
        @messages << [level, msg]
      end
    end

    def action?(name)
      if params[:action]
        params[:action].downcase == name.to_s
      else
        request.path_info.ends_with? '/' + name.to_s
      end
    end

    def fix_punctuation(text)
      safe_require('rubypants') ? RubyPants.new(text).to_html : text
    end
  end

  class Engine
    include Helper

    class NotAvailable < ArgumentError
      def initialize(name)
        super("Output engine #{name} is not available")
      end
    end
    
    attr_reader :name, :priority
    def layout?; @layout; end
    
    def initialize(name, priority, layout)
      @name = name
      @priority = priority
      @layout = layout
    end
    
    def self.create(name, priority, layout, &block)
      ENGINES << Class.new(Engine, &block).new(name, priority, layout)
    end

    def self.find(page, name = nil)
      engine = ENGINES.sort {|a,b| a.priority <=> b.priority }.
        find { |e| (name.blank? || e.name == name.to_sym) && e.accepts(page) }
      return engine if engine
      raise NotAvailable.new(name)
    end

    def self.accepts(&block)
      define_method :accepts, &block
    end

    def self.output(&block)
      define_method :output, &block
    end

    def self.mime(&block)
      define_method :mime, &block
    end

    accepts {|page| false }
    output  {|page| '' }
    mime    {|page| 'text/plain' }

    private

    ENGINES = []
  end

  class User < Entry
    attr_accessor :email
    attr_reader :password
    transient :anonymous

    def anonymous?; @anonymous; end

    def change_password(oldpassword, password, confirm)
      forbid('Passwords do not match' => password != confirm,
             'Password is wrong'      => @password != User.crypt(oldpassword))
      @password = User.crypt(password)
    end

    def author
      "#{@name} <#{@email}>"
    end

    def save
      forbid(
        'E-Mail is invalid' => @email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
        'Name is invalid'   => @name !~ /[\w.\-+_]+/,
        'Password is empty' => @password.blank?,
        'Anonymous'         => anonymous?
      )
      super
    end

    def self.anonymous(ip)
      User.new(ip, nil, "anonymous@#{ip}", true)
    end

    def self.authenticate(name, password)
      user = find(name)
      forbid('Wrong username or password' => !user || user.password != User.crypt(password))
      user
    end

    def self.create(name, password, confirm, email)
      forbid('Passwords do not match' => password != confirm,
             'User already exists'    => find(name))
      User.new(name, password, email, false).save
    end

    private

    def initialize(name, password, email, anonymous)
      super(name)
      @email = email
      @anonymous = anonymous
      @password = User.crypt(password)
    end

    def self.crypt(s)
      s.blank? ? s : Digest::SHA256.hexdigest(s)
    end
  end

  class App < Sinatra::Base
    pattern :path, PATH_PATTERN
    pattern :sha,  SHA_PATTERN

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
        @logger.info 'Opening repository'
        @repo = Git.open(App.config['workspace'], :repository => App.config['repository'],
                         :index => File.join(App.config['repository'], 'index'), :log => @logger)
      else
        @logger.info 'Initializing repository'
        @repo = Git.init(App.config['workspace'], :repository => App.config['repository'],
                         :index => File.join(App.config['repository'], 'index'), :log => @logger)
        page = Page.new(@repo, 'init.txt')
        page.write('This file is used to initialize the repository. It can be deleted.', 'Initialize Repository')
        @logger.info 'Repository initialized'
      end
      Entry.store = App.config['store']
    end

    def show(object = nil)
      object = Object.find!(@repo, params[:path], params[:sha]) if !object || object.new?
      if object.tree?
        @tree = object
        haml :tree
      else
        @page = object
        engine = Engine.find(@page, params[:output])
        @content = engine.output(@page)
        if engine.layout?
          haml :page
        else
          content_type engine.mime(@page).to_s
          @content
        end
      end
    end

    before do
      # Sinatra does not unescape before pattern matching
      # Paths with spaces won't be recognized
      # FIXME: Implement this as middleware?
      request.path_info = CGI::unescape(request.path_info)
      @logger.debug request.env
      content_type 'application/xhtml+xml', :charset => 'utf-8'
      @user = session[:user] || User.anonymous(request.ip)
      @footer = nil
      @feed = nil
      @title = ''
    end

    not_found do
      @error = request.env['sinatra.error']
      haml :error
    end

    error do
      @error = request.env['sinatra.error']
      haml :error
    end

    get '/' do
      redirect '/Home'
    end

    get '/login', '/signup' do
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

    get '/search' do
      matches = @repo.grep(params[:pattern], nil, :ignore_case => true)
      @matches = []
      matches.each_pair do |id,lines|
        if id =~ /^#{SHA_PATTERN}:(.+)$/
          @matches << [$1,lines.map {|x| x[1] }.join("\n").truncate(100)]
        end
      end
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
      @tree = Tree.find!(@repo, params[:path])
      content_type 'application/x-tar-gz'
      attachment "#{@tree.safe_name}.tar.gz"
      archive = @repo.archive(@tree.object.sha, nil, :format => 'tgz', :prefix => "#{@tree.safe_name}/")
      File.open(archive).read
    end

    get '/history', '/:path/history' do
      @object = Object.find!(@repo, params[:path])
      haml :history
    end

    get '/changelog.rss', '/:path/changelog.rss' do
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
      @object = Object.find!(@repo, params[:path], params[:from])
      @diff = @object.diff(params[:to])
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
        @page = Page.new(@repo, params[:path])
      rescue MessageError => error
        message :new, error.message
      end        
      haml :new
    end

    get '/:sha', '/:path/:sha', '/:path' do
      begin
        show
      rescue Object::NotFound
        redirect((params[:path]/'new').urlpath)
      end
    end

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

          if params[:preview]
            engine = Engine.find(@page)
            @preview_content = engine.output(@page) if engine.layout?
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

    post '/', '/:path' do
      begin
        @page = Page.new(@repo, params[:path])
        if action?(:upload) && params[:file]
          @page.write(params[:file][:tempfile].read, 'File uploaded', @user.author)
          redirect params[:path].urlpath
        elsif action?(:new)
          @page.content = params[:content]
          if params[:preview]
            engine = Engine.find(@page)
            @preview_content = engine.output(@page) if engine.layout?
            haml :new
          else
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
  end
end

safe_require_all(File.join(Wiki::App.root, 'plugins'))

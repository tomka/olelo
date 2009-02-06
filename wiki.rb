%w(
rubygems
sinatra_ext
git
haml
sass
creole
redcloth
rdiscount
rubypants
mime/types
logger
open3).each { |dep| require dep }

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
    lexer ? text(content, lexer) : content.html_escape
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

class Symbol
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end

class String

  def tail(max)
    i = length-max
    i = 0 if i < 0
    self[i..-1]
  end

  def cleanpath
    names = split('/')
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

  def abspath
    '/' + cleanpath
  end

  def html_escape
    gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
  end

  def truncate(max, omission = '...')
    (length > max ? self[0...max-3] + omission : self)
  end

  def /(name)
    (self + '/' + name).cleanpath
  end
end

module Wiki

  class InvalidOutput < Exception
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
  end

  class Object
    class NotFound < Sinatra::NotFound
      attr_reader :path
      
      def initialize(path)
        @path = path
      end
    end

    attr_reader :repo, :path, :commit, :object

    def self.find(repo, path, sha = nil)
      commit = sha ? repo.gcommit(sha) : repo.log(1).path(path).first
      create(repo, path, commit, Object.find_in_repo(repo, path, commit))
    end

    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound.new(path))
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
          path = path.cleanpath
          object = if path.empty?
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
    
    # FIXME: Author not used
    def update(new_content, message, author = nil)
      return if new_content == content
      message ||= ''
      message.gsub!("'", "'\\\\''") # FIXME: ruby-git bug
      repo.chdir {
        FileUtils.makedirs File.dirname(@path)
        File.open(@path, 'w') {|f| f << new_content }
      }
      repo.add(@path)
      repo.commit(message.empty? ? '(Empty commit message)' : message)
      @prev_commit = @history = nil
      @commit = head_commit
      @object = Object.find_in_repo(@repo, @path, @commit) || raise(NotFound.new(path))
    end

    def extension
      path =~ /\.([^\/]+)$/
      $1
    end

    def pretty_name
      name.gsub(/\.([^\/]+)$/, '')
    end
  end
  
  class Tree < Object
    def children
      x = @object.children.to_a.map {|x| Object.create(repo, path/x[0], commit, x[1]) }.compact
      x.each {|y| y.page? }
      x
    end

    def pretty_name
      '&radic;&macr;&macr;'/path
    end
  end

  class App < Sinatra::Base
    pattern :path, /.+/
    pattern :sha,   /[A-Fa-f0-9]{40}/
    
    set :haml, { :format => :xhtml, :attr_wrapper  => '"' }
    set :methodoverride, true
    set :static, true
    set :app_file, 'wiki.rb'
    set :raise_errors, false
    set :dump_errors, true

    class Engine
      attr_reader :name
      def layout?; @layout; end

      def initialize(name, layout)
        @name = name
        @layout = layout
      end

      def self.create(name, layout, &block)
        Class.new(Engine, &block).new(name, layout)
      end

      def self.find(page, name)
        engine = ENGINES.find { |e| (!name || e.name == name.to_sym) && e.accepts(page) }
        return engine if engine
        raise InvalidOutput.new(name)
      end

      def self.method_missing(sym, &block)
        define_method sym, &block
      end

      accepts {|page| false }
      output  {|page| '' }
      mime    {|page| 'text/plain' }

      ENGINES =
        [
         Engine.create(:css, false) {
           accepts {|page| page.extension == 'sass' }
           output  {|page| Sass::Engine.new(page.content).render }
           mime    {|page| 'text/css' }
         },
         Engine.create(:code, true) {
           accepts {|page| Highlighter.supports?(page.name) }
           output  {|page| Highlighter.file(page.content, page.name) }
         },
         Engine.create(:creole, true) {
           accepts {|page| page.extension == 'text' }
           output  {|page| RubyPants.new(Creole.creolize(page.content)).to_html }
         },
         Engine.create(:markdown, true) {
           accepts {|page| page.extension =~ /^(markdown|md|mdown|mkdn|mdown)$/  }
           output  {|page| RubyPants.new(RDiscount.new(page.content).to_html).to_html }
         },
         Engine.create(:textile, true) {
           accepts {|page| page.extension == 'textile'  }
           output  {|page| RubyPants.new(RedCloth.new(page.content).to_html).to_html }
         },
         Engine.create(:html, true) {
           accepts {|page| types = MIME::Types.of(page.path); types.empty? ? false : types.first.ascii? }
           output  {|page| '<pre>' + page.content.html_escape + '</pre>' }
           mime    {|page| MIME::Types.of(page.path).first.to_s }
         },
         Engine.create(:raw, false) {
           accepts {|page| true }
           output  {|page| page.content }
           mime    {|page| types = MIME::Types.of(page.path); types.empty? ? 'text/plain' : types.first.to_s }
         }
        ]
    end

    def menu(*enabled)
      haml :menu, :layout => false, :locals => { :enabled => enabled }
    end

    def initialize
      @logger = App.logger
      if File.exists?(App.repository)
        @repo = Git.open(App.repository, :log => @logger)
      else
        @repo = Git.init(App.repository, :log => @logger)
        page = Page.new(@repo, '.init')
        page.update('.init', 'Initialize Repository')
      end
    end

    def object_path(object, commit = nil)
      commit ||= object.commit
      sha = commit.is_a?(String) ? commit : commit.sha      
      (object.head?(commit) ? object.path : object.path/sha).abspath
    end

    def child_path(tree, child)
      (tree.head? ? child.path : child.path/tree.commit.sha).abspath
    end

    def parent_path(tree)
      (tree.head? ? tree.path/'..' : tree.path/'..'/tree.commit.sha).abspath
    end

    def action_path(object, action)
      (object.path/action.to_s).abspath
    end

    def image_path(name)
      "/images/#{name}.png"
    end

    def show
      @object ||= Object.find!(@repo, params[:path], params[:sha])
      @title = @object.pretty_name
      if @object.tree?
        haml :tree
      else
        engine = Engine.find(@object, params[:output])
        @content = engine.output(@object)
        if engine.layout?
          haml :page
        else
          content_type engine.mime(@object)
          @content
        end
      end
    end

    def edit(append = false)
      @object = Object.find!(@repo, params[:path])
      if @object.page?
        @title = (append ? 'Append to ' : 'Edit ') + @object.pretty_name
        haml :edit, :locals => { :append => append }
      else
        redirect(@object.path.abspath)
      end
    end

    before do
      content_type 'application/xhtml+xml', :charset => 'utf-8'
    end

    not_found do
      redirect((params[:path]/'new').abspath) if params[:path]
      @error = request.env['sinatra.error']
      haml :error
    end

    error do
      @error = request.env['sinatra.error']
      haml :error
    end

    get '/style.css' do
      content_type 'text/css', :charset => 'utf-8'
      # FIXME: Should be wiki editable
      sass :style
    end
    
    get '/tarball' do
      content_type 'application/x-gzip'
      attachment 'archive.tar.gz'
      archive = @repo.archive('HEAD', nil, :format => 'tgz', :prefix => 'wiki/')
      File.open(archive).read
    end

    get '/:sha', '/:path/:sha' do
      params[:path] ||= ''
      show
    end

    get '/history', '/:path/history' do
      params[:path] ||= ''
      @object = Object.find!(@repo, params[:path])      
      @title = "History of #{@object.pretty_name}"
      haml :history
    end

    get '/diff', '/:path/diff' do
      params[:path] ||= ''
      @from = params[:from]
      @to = params[:to]
      @object = Object.find!(@repo, params[:path], @from)
      @title = "Diff of #{@object.pretty_name}"
      @diff = @object.diff(@to)
      haml :diff
    end

    get '/:path/edit' do
      edit
    end

    get '/:path/append' do
      edit(true)
    end

    get '/:path/new' do
      @path = params[:path]
      redirect(params[:path].abspath) if Object.find(@repo, @path)
      @title = "New #{@path}"
      haml :new
    end

    get '/', '/:path' do
      params[:path] ||= ''
      show
    end

    put '/:path' do
      @object = Object.find!(@repo, params[:path])
      if @object.page?
        params[:content] = @object.content + "\n" + params[:content] if params[:append] == '1'
        @object.update(params[:content], params[:message], request.ip)
      end
      show
    end

    post '/:path' do
      @object = Page.new(@repo, params[:path])
      if params[:file]
        @object.update(params[:file][:tempfile].read, 'File uploaded')
        show
      else
        @object.update(params[:content], params[:message], request.ip)
        show
      end
    end

  end
end

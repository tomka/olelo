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

  class NotFound < Sinatra::NotFound
    attr_reader :path
    
    def initialize(path)
      @path = path
    end
  end

  class FormatNotSupported < Exception
    attr_reader :format
    
    def initialize(format)
      @format = format
    end
  end

  class UnknownObject < Exception
    attr_reader :path
    
    def initialize(path)
      @path = path
    end
  end

  class Object
    attr_reader :repo, :path, :commit, :object

    def self.find(repo, path, sha = nil)
      commit = sha ? repo.gcommit(sha) : repo.log(1).first
      path = path.cleanpath
      object = Object.find_in_repo(repo, path, commit)
      create(repo, path, commit, object) || raise(UnknownObject.new(path))
    end
    
    def head?
      @repo.log(1).first.sha == @commit.sha
    end

    def history
      @history ||= @repo.log.path(path).to_a
    end

    def prev_commit
      @prev_commit ||= @repo.log(2).object(@commit.sha).path(@path).to_a[1]
    end

    def next_commit
      h = history
      h.each_index { |i|
        return (i == 0 ? nil : h[i - 1]) if h[i].committer_date <= @commit.committer_date
      }
      h.last
    end
      
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    def name_wo_ext
      name.gsub(/\.([^\/]+)$/, '')
    end

    def extension
      path =~ /\.([^\/]+)$/
      $1
    end

    def initialize(repo, path, commit = nil, object = nil)
      @repo = repo
      @path = path
      @commit = commit
      @object = object
    end

    private

    def self.create(repo, path, commit, object)
      return Page.new(repo, path, commit, object) if object.blob?
      return Tree.new(repo, path, commit, object) if object.tree?
      nil
    end

    def self.find_in_repo(repo, path, commit)
      object = if path.empty?
        commit.gtree
      elsif path =~ /\//
        path.split('/').inject(commit.gtree) { |t, x| t.children[x] } rescue nil
      else
        commit.gtree.children[path]
      end
      raise NotFound.new(path) if !object
      object
    end

  end

  class Page < Object
    def content
      @object ? @object.contents : nil
    end
    
    def update(new_content, message)
      return if new_content == content
      repo.chdir {
        FileUtils.makedirs File.dirname(@path)
        File.open(@path, 'w') {|f| f << new_content }
      }
      repo.add(@path)
      repo.commit(!message || message.empty? ? '(Empty commit message)' : message)
      @commit = repo.log(1).first
      @object = Object.find_in_repo(@repo, @path, @commit)
    end
  end
  
  class Tree < Object
    def children
      @object.children.to_a.map {|x| Object.create(repo, path/x[0], commit, x[1]) }.compact
    end
  end

  class App < Sinatra::Base
    pattern :path, /.+/
    pattern :sha,   /[A-Fa-f0-9]{40}/
    
    # FIXME DOES NOT WORK
    set :haml, { :format => :xhtml, :attr_wrapper  => '"' }
    set :methodoverride, true
    set :static, true
    set :app_file, 'wiki.rb'
    set :raise_errors, false
    set :dump_errors, true

    DEFAULT_FORMATS = [:html, :raw]

    def highlight(text, format)
      Open3.popen3("pygmentize -f html -l #{format}") { |stdin, stdout, stderr|
        stdin << text
        stdin.close
        stdout.read
      }
    end

    ENGINES =
      [
       {
         :format  => :css,
         :accepts => proc {|page| page.extension == 'sass' },
         :output  => proc {|page| Sass::Engine.new(page.content).render },
         :mime    => proc {|page| 'text/css' },
         :layout  => false,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.extension == 'rb' },
         :output  => proc {|page| highlight(page.content, 'ruby') },
         :layout  => true,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.extension == 'text' },
         :output  => proc {|page| RubyPants.new(Creole.creolize(page.content)).to_html },
         :layout  => true,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.extension =~ /^(markdown|md|mdown|mkdn|mdown)$/ },
         :output  => proc {|page| RubyPants.new(RDiscount.new(page.content).to_html).to_html },
         :layout  => true,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.extension == 'textile' },
         :output  => proc {|page| RubyPants.new(RedCloth.new(page.content).to_html).to_html },
         :layout  => true,
       },
       {
         :format  => :html,
         :accepts => proc {|page| types = MIME::Types.of(page.path); types.empty? ? true : types.first.ascii? },
         :output  => proc {|page| '<pre>' + page.content.html_escape + '</pre>' },
         :mime    => proc {|page| MIME::Types.of(page.path).first.to_s },
         :layout  => true,
       },
       {
         :format  => :raw,
         :accepts => proc {|page| true },
         :output  => proc {|page| page.content },
         :mime    => proc {|page| types = MIME::Types.of(page.path); types.empty? ? 'text/plain' : types.first.to_s },
         :layout  => false,
       },
      ]

    def initialize
      @log = Logger.new(STDOUT)
      @log.level = Logger::WARN
      if File.exists?(App.repository)
        @repo = Git.open(App.repository, :log => @log)
      else
        @repo = Git.init(App.repository, :log => @log)
        page = Page.new(@repo, '.init')
        page.update('.init', 'Initialize Repository')
      end
    end

    def object_path(object, commit = nil)
      path = object.path
      commit ||= object.commit
      path = path/commit.sha if commit.sha != @repo.log(1).first.sha
      path.abspath
    end

    def action_path(object, action)
      (object.path/action.to_s).abspath
    end

    def find_engine_for_format(page, format)
      ENGINES.find { |e| e[:format] == format.to_sym && e[:accepts].call(page) }
    end

    def find_engine(page, format)
      if format
        engine = find_engine_for_format(page, format)
        return engine if engine
      else
        DEFAULT_FORMATS.each { |format|
          engine = find_engine_for_format(page, format)
          return engine if engine
        }
      end
      raise FormatNotSupported.new(format)
    end

    def show
      @object ||= Object.find(@repo, params[:path], params[:sha])
      @title = @object.name_wo_ext
      if @object.tree?
        haml :tree
      else
        engine = find_engine(@object, params[:format])
        @content = engine[:output].call(@object)
        if engine[:layout]
          haml :page
        else
          content_type engine[:mime].call(@object)
          @content
        end
      end
    end

    def edit(append = false)
      @object = Object.find(@repo, params[:path])
      if @object.page?
        @title = (append ? 'Append to ' : 'Edit ') + @object.name_wo_ext
        haml :edit, :locals => { :append => append }
      else
        show
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

    get '/diff' do
      diff = @repo.diff(params[:from], params[:to])
      @title = "Diff between #{params[:from]} and #{params[:to]}"
      @diff = highlight(diff.patch, 'diff')
      haml :diff
    end

    get '/:sha', '/:path/:sha' do
      params[:path] ||= ''
      show
    end

    get '/history', '/:path/history' do
      params[:path] ||= ''
      @object = Object.find(@repo, params[:path])      
      @title = "History of #{@object.name_wo_ext}"
      haml :history
    end

    get '/:path/edit' do
      edit
    end

    get '/:path/append' do
      edit(true)
    end

    get '/:path/new' do
      @path = params[:path]
      @title = "New #{@path}"
      haml :new
    end

    get '/', '/:path' do
      params[:path] ||= ''
      show
    end

    put '/:path' do
      @object = Object.find(@repo, params[:path])
      if @object.page?
        params[:content] = @object.content + "\n" + params[:content] if params[:append] == '1'
        @object.update(params[:content], params[:message])
      end
      show
    end

    post '/:path' do
      @object = Page.new(@repo, params[:path])
      if params[:file]
        @object.update(params[:file][:tempfile].read, 'File uploaded')
        show
      else
        @object.update(params[:content], params[:message])
        show
      end
    end

  end
end

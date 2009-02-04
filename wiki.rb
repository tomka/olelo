#!/usr/bin/env ruby

%w(
rubygems
sinatra_ext
grit
haml
sass
creole
redcloth
rdiscount
mime/types).each { |dep| require dep }

class Symbol
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end

class String
  def cleanpath
    return self if self == '/'
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
    return self if self == '/'
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

    def self.find(repo, path, id = nil)
      path = path.cleanpath
      id ||= repo.head.commit
      commit = repo.commit(id)
      object = commit.tree/path
      raise NotFound.new(path) if !object
      create(repo, path, commit, object) || raise(UnknownObject.new(path))
    end

    def head?
      @repo.head.commit == @commit.id
    end

    def history
      @history ||= @repo.log(@repo.head.name, path)
    end

    def prev_commit
      history.each { |commit|
        return commit if commit.committed_date < @commit.committed_date
      }
      nil
    end

    def next_commit
      history.each_index { |i|
        return (i == 0 ? nil : history[i - 1]) if history[i].committed_date <= @commit.committed_date
      }
      history.last
    end
      
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    def extension
      path =~ /\.([^\/]+)$/
      $1
    end

    private

    def self.create(repo, path, commit, object)
      return Page.new(repo, path, commit, object) if object.is_a? Grit::Blob
      return Tree.new(repo, path, commit, object) if object.is_a? Grit::Tree
      nil
    end

    def initialize(repo, path, commit, object)
      @repo = repo
      @path = path
      @commit = commit
      @object = object
    end

    class Page < Object
      def content
        @object.data
      end
      
      def update(new_content, message)
        return if new_content == content
        Dir.chdir(repo.working_dir) {
          File.open(path, 'w') {|f| f << new_content }
          repo.add(path)
          repo.commit_index(message)
        }
      end
    end
    
    class Tree < Object
      def contents
        @object.contents.map {|object| Object.create(repo, path/object.name, commit, object) }.compact
      end
    end

  end

  class App < Sinatra::Base
    pattern :path, /.+/
    pattern :id,   /[A-Fa-f0-9]{40}/
    set :haml, { :format => :xhtml, :attr_wrapper  => '"' }
    set :methodoverride, true

    DEFAULT_FORMATS = [:html, :raw]

    ENGINES =
      [
       {
         :format  => :css,
         :accepts => proc {|page| page.path =~ /\.sass$/ },
         :output  => proc {|page| Sass::Engine.new(page.content).render },
         :mime    => proc {|page| 'text/css' },
         :layout  => false,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.path =~ /\.text$/ },
         :output  => proc {|page| Creole.creolize(page.content) },
         :layout  => true,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.path =~ /\.markdown$/ },
         :output  => proc {|page| RDiscount.new(page.content).to_html },
         :layout  => true,
       },
       {
         :format  => :html,
         :accepts => proc {|page| page.path =~ /\.textile$/ },
         :output  => proc {|page| RedCloth.new(page.content).to_html },
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
      base = File.join(File.dirname(__FILE__), 'repository')
      @repo = Grit::Repo.new(base)
    end

    def object_path(object, commit = nil)
      path = object.path
      commit ||= object.commit
      path = path/commit.id if commit.id != @repo.head.commit
      path.abspath
    end

    def action_path(object, action)
      (object.path/action.to_s).abspath
    end

    def find_engine_for_format(page, format)
      ENGINES.select { |e| e[:format] == format.to_sym }.each { |e|  return e if e[:accepts].call(page) }
      nil
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

    def find(path, id = nil)
      Object.find(@repo, path, id)
    end

    def show
      @object = find(params[:path], params[:id])
      @title = @object.path
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
    
    before do
      content_type 'application/xhtml+xml', :charset => 'utf-8'
    end

    get '/' do
      params[:path] = '/'
      show
    end

    get '/style.css' do
      content_type 'text/css', :charset => 'utf-8'
      # FIXME: Should be wiki editable
      sass :style
    end

    get '/:path/:id' do
      show
    end

    get '/:path/history' do
      @object = find(params[:path])      
      @title = "History of #{@object.path}"
      haml :history
    end

    get '/:path/edit' do
      @object = find(params[:path])
      if @object.page?
        @title = "Edit #{@object.path}"
        haml :edit
      else
        show
      end
    end

    get '/:path' do
      show
    end

    put '/:path' do
      @object = find(params[:path])
      if @object.page?
        @object.update(params[:content], params[:message])
        show
      else
        show
      end      
    end

#     get '/search' do
#       'search<br>' + params.inspect
#     end
    
#     get '/tarball' do
#       'tarball<br>' + params.inspect
#     end
    
#     get '/branches' do
#       'branches<br>' + params.inspect
#     end
    
#     get '/branch/new' do
#       'new branch<br>' + params.inspect
#     end
    
#     get '/branch/:branch' do
#       'branch<br>' + params.inspect
#     end
    
#     get '/branch/:branch/revert' do
#       'revert branch<br>' + params.inspect
#     end
    
#     get '/branch/:branch/merge' do
#       'merge branch<br>' + params.inspect
#     end
    
#     get '/branch/:branch/delete' do
#     'delete branch<br>' + params.inspect
#     end

#     get '/:path/list' do
#       'list<br>' + params.inspect
#     end

#     get '/:path/edit' do
#       'edit<br>' + params.inspect
#     end
   
#     get '/:path/new' do
#       'new<br>' + params.inspect
#     end

#     get '/:path/append' do
#       'append<br>' + params.inspect
#     end

#     get '/:path/history' do
#       'history<br>' + params.inspect
#     end

#     get '/:path/:rev/diff' do
#       'diff<br>' + params.inspect
#     end

#     post '/:path/append' do
#       'post append<br>' + params.inspect    
#     end

#     get '/:path/:rev' do
#       'show rev<br>' + params.inspect
#     end

#     get '/:path' do
#       #puts 'show<br>' + params.inspect
      
#     @path = get_path
#      
#      if @path.exists?
#        if @path.directory?
#          redirect "/#{@path}/list"
#        else
#          haml :show
#        end
#      else
#        redirect "/#{@path}/edit"
#      end
#     end
    
#     put '/:path' do
#       'put<br>' + params.inspect    
#     end
    
#     post '/:path' do
#       'post<br>' + params.inspect    
#     end
  end
end

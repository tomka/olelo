require 'sinatra/base'
require 'git'
require 'wiki/utils'
require 'wiki/extensions'
require 'wiki/config'

module Wiki
  PATH_PATTERN = '[\w:.+\-_\/](?:[\w:.+\-_\/ ]*[\w.+\-_\/])?'
  SHA_PATTERN = '[A-Fa-f0-9]{5,40}'
  STRICT_SHA_PATTERN = '[A-Fa-f0-9]{40}'

  # Wiki repository object
  class Object
    include Utils

    # Raised if object is not found in the repository
    class NotFound < Sinatra::NotFound
      def initialize(path)
        super("#{path} not found", path)
      end
    end

    attr_reader :repo, :path, :commit, :object

    # Find object in repo by path and commit sha
    def self.find(repo, path, sha = nil)
      path = path.to_s.cleanpath
      forbid_invalid_path(path)
      commit = sha ? repo.gcommit(sha) : repo.log(1).path(path).first rescue nil
      return nil if !commit
      object = git_find(repo, path, commit)
      return nil if !object
      return Page.new(repo, path, object, commit, !sha) if object.blob?
      return Tree.new(repo, path, object, commit, !sha) if object.tree?
      nil
    end

    # Find object but raise not found exceptions
    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound, path)
    end

    # Constructor
    def initialize(repo, path, object = nil, commit = nil, current = false)
      path = path.to_s.cleanpath
      forbid_invalid_path(path)
      @repo = repo
      @path = path.cleanpath
      @object = object
      @commit = commit
      @current = current
      @prev_commit = @latest_commit = @history = nil
    end

    # Newly created object, not yet in repository
    def new?
      !@object
    end

    # Object sha
    def sha
      new? ? '' : object.sha
    end

    # Browsing current tree?
    def current?
      @current || new?
    end

    # Latest commit of this object
    def latest_commit
      update_prev_latest_commit
      @latest_commit
    end

    # History of this object. It is truncated
    # to 30 entries.
    def history
      @history ||= @repo.log.path(path).to_a
    end

    # Previous commit this object was changed
    def prev_commit
      update_prev_latest_commit
      @prev_commit
    end

    # Next commit was changed
    def next_commit
      h = history
      h.each_index { |i| return (i == 0 ? nil : h[i - 1]) if h[i].committer_date <= @commit.committer_date }
      h.last # FIXME. Does not work correctly if history is too short
    end

    # Type shortcuts
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    # Object name
    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    # Pretty formatted object name
    def pretty_name
      name.gsub(/\.([^.]+)$/, '')
    end

    # Safe name
    def safe_name
      n = name
      n = 'root' if n.blank?
      n.gsub(/[^\w.\-_]/, '_')
    end

    # Diff of this object
    def diff(from, to)
      @repo.diff(from, to).path(path)
    end

    protected

    def update_prev_latest_commit
      if !@latest_commit
        commits = @repo.log(2).object(@commit.sha).path(@path).to_a
        @prev_commit = commits[1]
        @latest_commit = commits[0]
      end
    end

    static do
      protected

      def forbid_invalid_path(path)
	forbid('Invalid path' => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
      end

      def git_find(repo, path, commit)
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

  end

  # Page object in repository
  class Page < Object
    def initialize(repo, path, object = nil, commit = nil, current = nil)
      super
      @content = nil
    end

    # Find page by path and commit sha
    def self.find(repo, path, sha = nil)
      object = super
      object && object.page? ? object : nil
    end

    # Set page content for preview
    def preview_content=(content)
      @mime = nil
      @content = content
    end

    # Page content
    def content
      @content || (@object && @object.contents)
    end

    # Check if there is no unsaved content
    def saved?
      !new? && !@content
    end

    # Write page (commit)
    def write(content, message, author = nil)
      if !content.respond_to? :path
        content.gsub!("\r\n", "\n")
        return if @object && content == @object.contents
      end

      forbid('No content'   => content.blank?,
             'Object already exists' => new? && Object.find(@repo, @path),
             'Commit message is empty' => message.blank?)

      repo.chdir do
        FileUtils.makedirs File.dirname(@path)
        if content.respond_to? :path
          FileUtils.copy(content.path, @path)
        else
          File.open(@path, 'w') {|f| f << content }
        end
      end

      repo.add(@path)
      repo.commit(message, :author => author)

      @content = @prev_commit = @latest_commit = @history = nil
      @commit = history.first
      @object = git_find(@repo, @path, @commit) || raise(NotFound, path)
      @current = true
    end

    # Page extension
    def extension
      path =~ /.\.([^\/.]+)$/
      $1.to_s
    end

    # Detect mime type by extension, by content or use default mime type
    def mime
      @mime ||= Mime.by_extension(extension) || Mime.by_magic(content) || Mime.new(Config.default_mime)
    end
  end

  # Tree object in repository
  class Tree < Object
    def initialize(repo, path, object = nil, commit = nil, current = false)
      super
      @trees = nil
      @pages = nil
    end

    # Find tree by path and optional commit sha
    def self.find(repo, path, sha = nil)
      object = super
      object && object.tree? ? object : nil
    end

    # Get child pages
    def pages
      @pages ||= @object.blobs.to_a.map {|x| Page.new(repo, path/x[0], x[1], commit, current?)}.sort {|a,b| a.name <=> b.name }
    end

    # Get child trees
    def trees
      @trees ||= @object.trees.to_a.map {|x| Tree.new(repo, path/x[0], x[1], commit, current?)}.sort {|a,b| a.name <=> b.name }
    end

    # Get all children
    def children
      trees + pages
    end

    # Pretty name
    def pretty_name
      '&#8730;&#175; Root'/path
    end

    # Get archive of current tree
    def archive
      @repo.archive(sha, nil, :format => 'tgz', :prefix => "#{safe_name}/")
    end
  end
end

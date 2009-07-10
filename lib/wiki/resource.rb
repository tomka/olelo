require 'git'
require 'wiki/routing'
require 'wiki/utils'
require 'wiki/extensions'
require 'wiki/config'
require 'mimemagic'

module Wiki
  PATH_PATTERN = '[\w:.+\-_\/](?:[\w:.+\-_\/ ]*[\w.+\-_\/])?'
  SHA_PATTERN = '[A-Fa-f0-9]{5,40}'
  STRICT_SHA_PATTERN = '[A-Fa-f0-9]{40}'

  # Wiki repository resource
  class Resource
    # Raised if resource is not found in the repository
    class NotFound < Routing::NotFound
      def initialize(path)
        super(:not_found.t(:path => path), path)
      end
    end

    attr_reader :repo, :path, :commit

    # Find resource in repo by path and commit sha
    def self.find(repo, path, sha = nil)
      path = path.to_s.cleanpath
      forbid_invalid_path(path)
      commit = sha ? repo.gcommit(sha) : repo.log(1).path(path).first rescue nil
      return nil if !commit
      object = git_find(path, commit)
      return nil if !object
      return Page.new(repo, path, object, commit, !sha) if object.blob?
      return Tree.new(repo, path, object, commit, !sha) if object.tree?
      nil
    end

    # Find resource but raise not found exceptions
    def self.find!(repo, path, sha = nil)
      find(repo, path, sha) || raise(NotFound, path)
    end

    # Constructor
    def initialize(repo, path, object = nil, commit = nil, current = false)
      path = path.to_s.cleanpath
      Resource.forbid_invalid_path(path)
      @repo = repo
      @path = path.cleanpath
      @object = object
      @commit = commit
      @current = current
      @prev_commit = @latest_commit = @history = nil
    end

    # Newly created resource, not yet in repository
    def new?
      !@object
    end

    # Resource sha
    def sha
      new? ? '' : @object.sha
    end

    # Browsing current tree?
    def current?
      @current || new?
    end

    # Latest commit of this resource
    def latest_commit
      update_prev_latest_commit
      @latest_commit
    end

    # History of this resource. It is truncated
    # to 30 entries.
    def history
      @history ||= @repo.log.path(path).to_a
    end

    # Previous commit this resource was changed
    def prev_commit
      update_prev_latest_commit
      @prev_commit
    end

    # Next commit was changed
    def next_commit
      h = history
      h.each_index { |i| return (i == 0 ? nil : h[i - 1]) if h[i].date <= @commit.date }
      h.last # FIXME. Does not work correctly if history is too short
    end

    # Type shortcuts
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    # Resource name
    def name
      return $1 if path =~ /\/([^\/]+)$/
      path
    end

    # Pretty formatted resource name
    def pretty_name
      name.gsub(/\.([^.]+)$/, '')
    end

    # Safe name
    def safe_name
      n = name
      n = 'root' if n.blank?
      n.gsub(/[^\w.\-_]/, '_')
    end

    # Diff of this resource
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

    def self.forbid_invalid_path(path)
      forbid(:invalid_path.t => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
    end

    def self.git_find(path, commit)
      return nil if !commit
      if path.blank?
        commit.gtree rescue nil
      elsif path =~ /\//
        path.split('/').inject(commit.gtree) { |t, x| t.children[x] } rescue nil
      else
        commit.gtree.children[path] rescue nil
      end
    end
  end

  # Page resource in repository
  class Page < Resource
    def initialize(repo, path, object = nil, commit = nil, current = nil)
      super
      @content = nil
    end

    # Find page by path and commit sha
    def self.find(repo, path, sha = nil)
      resource = super
      resource && resource.page? ? resource : nil
    end

    # Set page content for preview
    def content=(content)
      @mime = nil
      @content = content
    end

    # Page content
    def content(pos = nil, len = nil)
      c = @content || (@object && @object.contents)
      pos ? c[[[0, pos.to_i].max, c.size].min, [0, len.to_i].max] : c
    end

    # Check if there is no unsaved content
    def saved?
      !new? && !@content
    end

    # Write page and commit
    def write(content, message, author = nil)
      if !content.respond_to? :path
        content.gsub!("\r\n", "\n")
	return if @object && @object.contents == content
      end

      forbid(:no_content.t => content.blank?,
             :already_exists.t => new? && Resource.find(@repo, @path),
             :empty_commit_message.t => message.blank?)

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
      @object = Resource.git_find(@path, @commit) || raise(NotFound, path)
      @current = true
    end

    # Page extension
    def extension
      path =~ /.\.([^\/.]+)$/
      $1.to_s
    end

    # Detect mime type by extension, by content or use default mime type
    def mime
      @mime ||= MimeMagic.by_extension(extension) ||
        (Config.mime.magic && MimeMagic.by_magic(content)) ||
        MimeMagic.new(Config.mime.default)
    end
  end

  # Tree resource in repository
  class Tree < Resource
    def initialize(repo, path, object = nil, commit = nil, current = false)
      super
      @trees = nil
      @pages = nil
    end

    # Find tree by path and optional commit sha
    def self.find(repo, path, sha = nil)
      resource = super
      resource && resource.tree? ? resource : nil
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
      :root_path.t/path
    end

    # Get archive of current tree
    def archive
      @repo.archive(sha, nil, :format => 'tgz', :prefix => "#{safe_name}/")
    end
  end
end

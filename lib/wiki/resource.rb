# -*- coding: utf-8 -*-
require 'wiki/routing'
require 'wiki/utils'
require 'wiki/extensions'
require 'wiki/config'
require 'yaml'

gem 'gitrb', '>= 0.0.2'
require 'gitrb'

gem 'mimemagic', '>= 0.1.1'
require 'mimemagic'

module Wiki
  PATH_PATTERN = '[^\s](?:.*[^\s]+)?'
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

    attr_reader :repository, :path, :commit

    # Find resource in repository by path and commit sha
    def self.find(repository, path, sha = nil)
      path = path.to_s.cleanpath
      forbid_invalid_path(path)
      commit = sha ? (String === sha ? repository.get_commit(sha) : sha) : repository.log(1, nil).first
      return nil if !commit
      object = commit.tree[path] rescue nil
      object && (self != Resource ? self.type == object.type && new(repository, path, object, commit, !sha) :
                 object.type == 'blob' && Page.new(repository, path, object, commit, !sha) ||
                 object.type == 'tree' && Tree.new(repository, path, object, commit, !sha)) || nil
    end

    # Find resource but raise not found exceptions
    def self.find!(repository, path, sha = nil)
      find(repository, path, sha) || raise(NotFound, path)
    end

    # Constructor
    def initialize(repository, path, object = nil, commit = nil, current = false)
      path = path.to_s.cleanpath
      Resource.forbid_invalid_path(path)
      @repository = repository
      @path = path.cleanpath
      @object = object
      @commit = commit
      @current = current
      reload
    end

    # Delete page
    def delete(author = nil)
      repository.transaction(:resource_deleted.t(:path => @path), author && author.to_git_user) do
        repository.root.delete(@path)
      end
    end

    # Move page
    def move(destination, author = nil)
      Resource.forbid_invalid_path(destination)
      forbid(:already_exists.t => Resource.find(@repository, destination))
      repository.transaction(:resource_moved_to.t(:path => @path, :destination => destination), author && author.to_git_user) do
        repository.root.move(@path, destination)
        repository.root[@path] = Gitrb::Blob.new(:data => %{<redirect path="#{destination.urlpath}"/>})
      end
      @path = destination
      reload
    end

    # Reload cached data
    def reload
      @prev_commit = @latest_commit = @history = nil
    end

    # Newly created resource, not yet in repository
    def new?
      !@object
    end

    # Modified resource, not yet saved
    def modified?
      new?
    end

    # Resource sha
    def sha
      new? ? '' : @object.id
    end

    # Browsing current tree?
    def current?
      @current || new?
    end

    # Latest commit of this resource
    def latest_commit
      init_commits
      @latest_commit
    end

    # History of this resource. It is truncated
    # to 30 entries.
    def history
      @history ||= @repository.log(30, nil, path)
    end

    # Previous commit this resource was changed
    def prev_commit
      init_commits
      @prev_commit
    end

    # Next commit was changed
    def next_commit
      h = history
      h.each_index { |i| return (i != 0 && h[i - 1]) if h[i].date <= @commit.date }
      h.last # FIXME. Does not work correctly if history is too short
    end

    # Type shortcuts
    def page?; self.class == Page; end
    def tree?; self.class == Tree; end

    # Resource name
    def name
      path =~ %r{/?([^/]+)$} ? $1 : path
    end

    # Page title
    def title
      i = name.index('.')
      n = i ? name[0...i] : name
      discussion? ? :discussion_of.t(:name => n[1..-1]) : n
    end

    # Discussion page
    def discussion?
      name.begins_with?('@')
    end

    # Safe name
    def safe_name
      n = name
      n = 'root' if n.blank?
      n.gsub(/[^\w.\-_]/, '_')
    end

    # Diff of this resource
    def diff(from, to)
      @repository.diff(from, to, path)
    end

    protected

    def init_commits
      if !@latest_commit
        commits = @repository.log(2, @commit, @path)
        @prev_commit = commits[1]
        @latest_commit = commits[0]
      end
    end

    def self.forbid_invalid_path(path)
      forbid(:invalid_path.t => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
    end
  end

  # Page resource in repository
  class Page < Resource
    def self.type
      'blob'
    end

    # Reload cached data
    def reload
      super
      @content = @metadata = nil
    end

    # Set page content for preview
    def content=(content)
      @mime = @metadata = nil
      @content = content
    end

    # Page content
    def content(pos = nil, len = nil)
      c = @content || (@object && @object.data)
      pos ? c[[[0, pos.to_i].max, c.size].min, [0, len.to_i].max] : c
    end

    # Check if there is no unsaved content
    def modified?
      new? || @content
    end

    # Write page and commit
    def write(content, message, author = nil)
      if !content.respond_to? :path
        content.gsub!("\r\n", "\n")
	return if @object && @object.data == content
      end

      forbid(:no_content.t => content.blank?,
             :already_exists.t => new? && Resource.find(@repository, @path),
             :empty_commit_message.t => message.blank?)

      repository.transaction(message, author && author.to_git_user) do
        content = File.read(content.path) if content.respond_to? :path # FIXME
        repository.root[@path] = Gitrb::Blob.new(:data => content)
      end

      reload
      @commit = latest_commit
      @object = @commit.tree[@path] || raise(NotFound, path)
      @current = true
    end

    # Page extension
    def extension
      i = path.index('.')
      i ? path[i+1..-1] : ''
    end

    # Detect mime type by extension, by content or use default mime type
    def mime
      @mime ||= MimeMagic.by_extension(extension) ||
        (Config.mime.magic && MimeMagic.by_magic(content)) ||
        MimeMagic.new(Config.mime.default)
    end

    # Get metadata
    def metadata
      @metadata ||= if path.ends_with?('meta') || (mime.text? && content =~ /^---\r?\n/)
        hash = YAML.load(content + "\n") rescue nil
        Hash === hash ? hash.with_indifferent_access : {}
      else
        page = Page.find(repository, path + '.meta', current? ? nil : commit)
        page ? page.metadata : {}
      end
    end
  end

  # Tree resource in repository
  class Tree < Resource
    DIRECTORY_MIME = MimeMagic.new('inode/directory')

    def self.type
      'tree'
    end

    # Reload cached data
    def reload
      super
      @pages = @trees = @metadata = nil
    end

    # Get all children
    def children
      trees + pages
    end

    def pages
      @pages ||= @object.select {|name, child| name[0..0] != '@' && child.type == 'blob' }.map {|name, child|
      	Page.new(repository, path/name, child, commit, current?) }
    end

    def trees
      @trees ||= @object.select {|name, child| name[0..0] != '@' && child.type == 'tree' }.map {|name, child|
      	Tree.new(repository, path/name, child, commit, current?) }
    end

    # Tree title
    def title
      path.blank? ? :root_path.t : super
    end

    # Get archive of current tree
    def archive
      file = Tempfile.new('archive').path
      @repository.git_archive(sha, nil, '--format=zip', "--prefix=#{safe_name}/", "--output=#{file}")
      file
    end

    # Directory mime type
    def mime
      DIRECTORY_MIME
    end

    # Get metadata
    def metadata
      @metadata ||= begin
                      page = Page.find(@repository, path/'meta', commit)
                      page ? page.metadata : {}
                    end
    end
  end
end

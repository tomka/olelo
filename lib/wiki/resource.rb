# -*- coding: utf-8 -*-
require 'wiki/routing'
require 'wiki/config'

gem 'gitrb', '>= 0.0.2'
require 'gitrb'

module Wiki
  PATH_PATTERN = '[^\s](?:.*[^\s]+)?'
  VERSION_PATTERN = '([A-Fa-f0-9]{5,40}|[\w\-\.]+)([\^~](\d+)?)*'
  DISCUSSION_PREFIX = '@'
  META_PREFIX = '$'
  DIRECTORY_MIME = MimeMagic.new('inode/directory')
  YAML_MIME = MimeMagic.new('text/x-yaml')

  # Wiki repository resource
  class Resource
    # Raised if resource is not found in the repository
    class NotFound < Routing::NotFound
      def initialize(path)
        super(:not_found.t(:path => path), path)
      end
    end

    attr_reader :repository, :path, :commit

    # Find resource in repository by path and commit version
    def self.find(repository, path, version = nil)
      path = path.to_s.cleanpath
      forbid_invalid_path(path)
      commit = version ? (String === version ? repository.get_commit(version) : version) : repository.log(1, nil).first
      return nil if !commit
      object = commit.tree[path] rescue nil
      object && (self != Resource ? self.type == object.type && new(repository, path, object, commit, !version) :
                 object.type == 'blob' && Page.new(repository, path, object, commit, !version) ||
                 object.type == 'tree' && Tree.new(repository, path, object, commit, !version)) || nil
    end

    # Find resource but raise not found exceptions
    def self.find!(repository, path, version = nil)
      find(repository, path, version) || raise(NotFound, path)
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
    def move(destination, author = nil, create_redirect = false)
      Resource.forbid_invalid_path(destination)

      resource = Resource.find(@repository, destination)
      if resource && resource.tree?
        destination = destination/name
        resource = Resource.find(@repository, destination)
      end

      Wiki.forbid(:already_exists.t(:path => destination) => resource)

      repository.transaction(:resource_moved_to.t(:path => @path, :destination => destination), author && author.to_git_user) do
        repository.root.move(@path, destination)
        repository.root[@path] = Gitrb::Blob.new(:data => %{<redirect path="#{destination.urlpath}"/>}) if create_redirect
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

    # Resource version
    def version
      new? ? '' : @object.id
    end

    # Browsing current tree?
    def current?
      @current || new?
    end

    # Discussion page
    def discussion?
      page? && name.begins_with?(DISCUSSION_PREFIX)
    end

    # Metadata page
    def meta?
      page? && name.begins_with?(META_PREFIX)
    end

    def discussion_path
      path/"../#{DISCUSSION_PREFIX}#{name}"
    end

    def meta_path
      path/"../#{META_PREFIX}#{name}"
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
      i = path.rindex('/')
      name = i ? path[i+1..-1] : path
    end

    # Resource name without extension
    def name_without_extension
      tmp = name
      i = tmp.index('.')
      i ? tmp[0...i] : tmp
    end

    # Page title
    def title
      if meta?
        name = name_without_extension
        name = name[META_PREFIX.length..-1]
        :metadata_of.t(:name => name.blank? ? :root_path.t : name)
      elsif discussion?
        name = name_without_extension
        name = name[DISCUSSION_PREFIX.length..-1]
        :discussion_of.t(:name => name.blank? ? :root_path.t : name)
      else
        name = metadata['title'] || name_without_extension
        name.blank? ? :root_path.t : name
      end
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

    # Get metadata
    def metadata
      @metadata ||= begin
                      page = Page.find(@repository, meta_path, commit)
                      page ? page.metadata : {}
                    end
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
      Wiki.forbid(:invalid_path.t => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
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
      if c
        # Try to encode with the standard wiki encoding utf-8
        # If it is not valid utf-8 we fall back to binary
        c.force_encoding(__ENCODING__)
        c.force_encoding(Encoding::ASCII_8BIT) if !c.valid_encoding?
        if pos
          c[[[0, pos.to_i].max, c.size].min, [0, len.to_i].max]
        else
          c
        end
      end
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

      Wiki.forbid(:no_content.t => content.blank?,
                  :already_exists.t(:path => @path) => new? && Resource.find(@repository, @path),
                  :empty_commit_message.t => message.blank?)

      repository.transaction(message, author && author.to_git_user) do
        content = File.read(content.path) if content.respond_to? :path # FIXME
        repository.root[@path] = Gitrb::Blob.new(:data => content)
      end

      reload
      @commit = repository.log(1, nil).first
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
      @mime ||= if meta?
                  YAML_MIME
                else
                  MimeMagic.by_extension(extension) ||
                    (Config.mime.magic && MimeMagic.by_magic(content)) ||
                    MimeMagic.new(Config.mime.default)
                end
    end

    # Get metadata
    def metadata
      @metadata ||= if meta? || (mime.text? && content =~ /^---\r?\n/)
                      hash = YAML.load("#{content}\n") rescue nil
                      Hash === hash ? hash.with_indifferent_access : {}
                    else
                      super
                    end
    end
  end

  # Tree resource in repository
  class Tree < Resource
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
      @pages ||= @object.select {|name, child| child.type == 'blob' }.map {|name, child|
        Page.new(repository, path/name, child, commit, current?) }.select {|page| !page.discussion? && !page.meta? }
    end

    def trees
      @trees ||= @object.select {|name, child| child.type == 'tree' }.map {|name, child|
        Tree.new(repository, path/name, child, commit, current?) }
    end

    # Directory mime type
    def mime
      DIRECTORY_MIME
    end
  end
end

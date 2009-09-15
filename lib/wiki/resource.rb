# -*- coding: utf-8 -*-
require 'git'
require 'wiki/routing'
require 'wiki/utils'
require 'wiki/extensions'
require 'wiki/config'
require 'mimemagic'
require 'yaml'

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

    attr_reader :repo, :path, :commit

    # Find resource in repo by path and commit sha
    def self.find(repo, path, sha = nil)
      path = path.to_s.cleanpath
      forbid_invalid_path(path)
      commit = sha ? (String === sha ? repo.gcommit(sha) : sha) : repo.log(1).path(path).first rescue nil
      return nil if !commit
      object = find_object(path, commit)
      object && (self != Resource ? valid_object?(object) && new(repo, path, object, commit, !sha) :
                 object.blob? && Page.new(repo, path, object, commit, !sha) ||
                 object.tree? && Tree.new(repo, path, object, commit, !sha)) || nil
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
      new? ? '' : @object.sha
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
      @history ||= @repo.log.path(path).to_a
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
      n = name.gsub(/\.([^.]+)$/, '')
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
      @repo.diff(from, to).path(path)
    end

    protected

    def init_commits
      if !@latest_commit
        commits = @repo.log(2).object(@commit.sha).path(@path).to_a
        @prev_commit = commits[1]
        @latest_commit = commits[0]
      end
    end

    def self.forbid_invalid_path(path)
      forbid(:invalid_path.t => (!path.blank? && path !~ /^#{PATH_PATTERN}$/))
    end

    def self.find_object(path, commit)
      return nil if !commit
      if path.blank?
        commit.gtree rescue nil
      else
        path.split('/').inject(commit.gtree) { |t, x| t.children[x] } rescue nil
      end
    end
  end

  # Page resource in repository
  class Page < Resource
    def self.valid_object?(object)
      object.blob?
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
      c = @content || (@object && @object.contents)
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

      reload
      @commit = history.first
      @object = Resource.find_object(@path, @commit) || raise(NotFound, path)
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

    # Get metadata
    def metadata
      @metadata ||= if path.ends_with?('meta') || (mime.text? && content =~ /^---\r?\n/)
        hash = YAML.load(content + "\n") rescue nil
        Hash === hash ? hash.with_indifferent_access : {}
      else
        page = Page.find(repo, path + '.meta', current? ? nil : commit)
        page ? page.metadata : {}
      end
    end
  end

  # Tree resource in repository
  class Tree < Resource
    DIRECTORY_MIME = MimeMagic.new('inode/directory')

    def self.valid_object?(object)
      object.tree?
    end

    # Reload cached data
    def reload
      super
      @pages = @trees = @metadata = nil
    end

    # Get child pages
    def pages
      @pages ||= @object.blobs.to_a.map {|x| Page.new(repo, path/x[0], x[1], commit, current?)}.sort_by {|a| a.name }
    end

    # Get child trees
    def trees
      @trees ||= @object.trees.to_a.map {|x| Tree.new(repo, path/x[0], x[1], commit, current?)}.sort_by {|a| a.name }
    end

    # Get all children
    def children
      trees + pages
    end

    # Tree title
    def title
      path.blank? ? :root_path.t : super
    end

    # Get archive of current tree
    def archive
      @repo.archive(sha, nil, :format => 'tgz', :prefix => "#{safe_name}/")
    end

    # Directory mime type
    def mime
      DIRECTORY_MIME
    end

    # Get metadata
    def metadata
      @metadata ||= begin
                      page = Page.find(@repo, path/'meta', commit)
                      page ? page.metadata : {}
                    end
    end
  end
end

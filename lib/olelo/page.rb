# -*- coding: utf-8 -*-
module Olelo
  class Version
    attr_reader :id, :author, :date, :comment, :parents

    def initialize(id, author, date, comment, parents)
      @id = id
      @author = author
      @date = date
      @comment = comment
      @parents = parents
    end

    def self.find(id)
      repository.find_version(id)
    end

    def self.find!(id)
      find(id) || raise(NotFound, id)
    end

    def short
      Version.short(id)
    end

    def self.short(id)
      repository.short_version(id)
    end

    def to_s
      id
    end

    def ==(other)
      other.to_s == id
    end

    def self.repository
      Repository.instance
    end
  end

  Diff = Struct.new(:from, :to, :patch)

  class Page
    include Util

    PATH_PATTERN = '[^\s](?:.*[^\s]+)?'

    attr_reader :path, :tree_version
    attr_reader? :current

    def initialize(path, tree_version = nil, current = true)
      @path = path.to_s.cleanpath.freeze
      @tree_version = tree_version
      @current = current
    end

    def self.transaction(comment, user = nil, &block)
      raise :empty_comment.t if comment.blank?
      repository.transaction(comment, user, &block)
    end

    def self.find(path, tree_version = nil)
      path = path.to_s.cleanpath
      raise :invalid_path.t if !path.blank? && path !~ /^#{PATH_PATTERN}$/
      repository.find_page(path, tree_version, tree_version.blank?)
    end

    def self.find!(path, tree_version = nil)
      find(path, tree_version) || raise(NotFound, path)
    end

    def root?
      path.empty?
    end

    def next_version
      init_versions
      @next_version
    end

    def previous_version
      init_versions
      @previous_version
    end

    def version
      init_versions
      @version
    end

    def history(skip = nil, limit = nil)
      repository.load_history(self, skip, limit)
    end

    def parent
      @parent ||= repository.find_page(path/'..', tree_version, current?) ||
        Page.new(path/'..', tree_version, current?) if !root?
    end

    def move(destination)
      destination = destination.to_s.cleanpath
      raise :already_exists.t(:path => destination) if Page.find(destination)
      repository.move(self, destination)
    end

    def delete
      repository.delete(self)
    end

    def diff(from, to)
      repository.diff(from, to, path)
    end

    def new?
      !tree_version
    end

    def modified?
      @modified || new?
    end

    def name
      if root?
        :root.t
      else
        i = path.rindex('/')
        name = i ? path[i+1..-1] : path
      end
    end

    def title
      attributes['title'] || name
    end

    def extension
      i = path.index('.')
      i ? path[i+1..-1] : ''
    end

    def safe_name
      name.gsub(/[^\w.\-_]/, '_')
    end

    def committed(path, tree_version)
      @path = path.freeze
      @tree_version = tree_version
      @modified = false
      @version = @next_version = @previous_version =
        @attributes = @parent = @children =
        @content = @mime = nil
    end

    def attributes
      @attributes ||= new? ? {} : repository.load_attributes(self)
    end

    def content
      @content ||= new? ? nil : repository.load_content(self)
    end

    def content=(content)
      @modified = true
      @mime = nil
      @content = content
    end

    def save
      raise :already_exists.t(:path => path) if new? && Page.find(path)
      repository.save(self)
    end

    def mime
      @mime ||= detect_mime
    end

    def children
      @children ||= repository.children(self).sort_by(&:name)
    end

    private

    def detect_mime
      return MimeMagic.new('application/x-empty') if !content
      return MimeMagic.new(attributes['mime']) if attributes['mime']
      Config.mime.each do |mime|
        mime = case mime
               when 'extension'
                 MimeMagic.by_extension(extension)
               when 'content', 'magic'
                 MimeMagic.by_magic(content)
               else
                 MimeMagic.new(mime)
               end
        return mime if mime
      end
    end

    def init_versions
      if !@version && @tree_version
        @previous_version, @version, @next_version = repository.load_version(self)
      end
    end

    def self.repository
      Repository.instance
    end

    def repository
      Repository.instance
    end
  end

  class Repository
    include Util
    extend Factory

    class << self
      attr_writer :instance
      def instance
        @instance ||= self[Config.repository.type].new(Config.repository[Config.repository.type])
      end
    end

    def short_version(version)
      version
    end
  end
end

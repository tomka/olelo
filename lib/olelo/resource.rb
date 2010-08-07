# -*- coding: utf-8 -*-
module Olelo
  class Version < Struct.new(:id, :author, :date, :comment, :parents)
    def self.find(id)
      Repository.instance.find_version(id)
    end

    def self.find!(id)
      find(id) || raise(NotFound, id)
    end

    def short
      Version.short(id)
    end

    def self.short(id)
      Repository.instance.short_version(id)
    end

    def to_s
      id
    end

    def ==(other)
      other.to_s == id
    end
  end

  Diff = Struct.new(:from, :to, :patch)

  class Namespace
    attr_reader :name, :prefix
    attr_reader? :metadata

    def initialize(name, prefix, metadata)
      @name = name.to_sym
      @prefix = prefix.freeze
      @metadata = metadata
    end

    def title(page)
      (metadata? ? :"#{name}_metadata_title" : :"#{name}_title").t(:name => page[prefix.length..-1])
    end

    class << self
      def reset
        @namespaces = @metadata_namespaces = @page_namespaces = nil
      end

      def find(name)
        namespaces.find { |ns| !ns.prefix.empty? && name.begins_with?(ns.prefix) } || main
      end

      def page(name)
        page_namespaces[name.to_sym] || raise("Invalid page namespace '#{name}'")
      end

      def metadata(name)
        metadata_namespaces[name.to_sym] || raise("Invalid metadata namespace '#{name}'")
      end

      def main
        @main ||= Namespace.page(:main)
      end

      def page_namespaces
        @page_namespaces ||= Hash[*Config.namespaces.map do |name, prefix|
          [name.to_sym, Namespace.new(name, prefix[0], false)]
        end.flatten]
      end

      def metadata_namespaces
        @metadata_namespaces ||= Hash[*Config.namespaces.map do |name, prefix|
          [name.to_sym, Namespace.new(name, prefix[1], true)]
        end.flatten]
      end

      def namespaces
        @namespaces ||= page_namespaces.values + metadata_namespaces.values
      end
    end
  end

  class Resource
    include Util

    PATH_PATTERN = '(?:[^\s](?:.*[^\s]+)?)?'
    PATH_REGEXP  = /^#{PATH_PATTERN}$/

    attr_reader :path, :tree_version
    attr_reader? :current

    def initialize(path, tree_version = nil, current = true)
      @path = path.to_s.cleanpath.freeze
      @tree_version = tree_version
      @current = current
      @next_version = @previous_version = @version = @parent = nil
    end

    def self.transaction(comment, user = nil, &block)
      raise :empty_comment.t if comment.blank?
      Repository.instance.transaction(comment, user, &block)
    end

    def self.find(path, tree_version = nil)
      path = path.to_s.cleanpath

      raise :invalid_path.t if path !~ PATH_REGEXP

      p = path.split('/')
      raise :invalid_path.t if Namespace.namespaces.any? do |ns|
        !ns.prefix.empty? && (p.last == ns.prefix || p[0..-2].any? {|x| x.begins_with?(ns.prefix) })
      end

      Repository.instance.find_resource(path, tree_version, !tree_version, Resource == self ? nil : self)
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

    def history
      @history ||= Repository.instance.history(self)
    end

    def parent
      @parent ||= Repository.instance.find_resource(path/'..', tree_version, current?, Tree) ||
        Tree.new(path/'..', tree_version, current?) if !root?
    end

    def move(destination)
      destination = destination.to_s.cleanpath
      check_modifiable
      raise :already_exists.t(:path => destination) if Resource.find(destination)
      Repository.instance.move(self, destination)
    end

    def delete
      check_modifiable
      Repository.instance.delete(self)
    end

    def diff(from, to)
      Repository.instance.diff(from, to, path)
    end

    def page?
      Page === self
    end

    def tree?
      Tree === self
    end

    def new?
      !tree_version
    end

    def modified?
      new?
    end

    def namespace_path(ns)
      old_ns = namespace
      old_ns == ns ? @path : (@path/'..'/(ns.prefix + name[old_ns.prefix.length..-1]))
    end

    def title
      metadata[:title] || namespace.title(name)
    end

    def name
      if root?
        Config.root_path
      else
        i = path.rindex('/')
        name = i ? path[i+1..-1] : path
      end
    end

    def safe_name
      name.gsub(/[^\w.\-_]/, '_')
    end

    def committed(path, tree_version)
      @path = path.freeze
      @tree_version = tree_version
      @metadata = @version = @next_version = @previous_version = @history = @parent = nil
    end

    def metadata
      @metadata ||= Page.find(namespace_path(Namespace.metadata(namespace.name)), tree_version).try(:metadata) || {}
    end

    protected

    def check_modifiable
      raise 'Tree not current' if !current?
    end

    def init_versions
      if !@version && @tree_version
        @previous_version, @version, @next_version = Repository.instance.version(self)
      end
    end
  end

  class Page < Resource
    YAML_MIME = MimeMagic.new('text/x-yaml')
    YAML_REGEXP = /(\A[\-\w_]+:.*?(\r?\n\r?\n|(\r?\n)?\Z))|(\A---\r?\n.*?(\r?\n---|\r?\n\.\.\.|\r?\n\r?\n|(\r?\n)?\Z))/m

    def namespace
     Namespace.find(name)
    end

    def content(pos = nil, len = nil)
      c = @content || saved_content
      if c
        # Try to encode with the standard wiki encoding utf-8
        # If it is not valid utf-8 we fall back to binary
        if c.respond_to? :force_encoding
	  c.force_encoding(__ENCODING__)
          c.force_encoding(Encoding::BINARY) if !c.valid_encoding?
        end
	if pos
          start = [[0, pos.to_i].max, c.size].min
          c[start ... start + [0, len.to_i].max]
        else
          c
        end
      end
    end

    def content=(content)
      @mime = @metadata = nil
      @content = content
    end

    def write(content)
      if String === content
        content.gsub!("\r\n", "\n")
        return if saved_content == content
      end

      raise :already_exists.t(:path => path) if new? && Resource.find(path)
      Repository.instance.write(self, content)
    end

    def committed(path, tree_version)
      super
      @saved_content = @content = @mime = nil
    end

    def modified?
      new? || @content
    end

    def extension
      i = path.index('.')
      i ? path[i+1..-1] : ''
    end

    def mime
      if !@mime
        if namespace.metadata?
          @mime = YAML_MIME
        else
          Config.mime.any? do |mime|
            @mime = case mime
                    when 'extension'
                      MimeMagic.by_extension(extension)
                    when 'content', 'magic'
                      MimeMagic.by_magic(content)
                    else
                      MimeMagic.new(mime)
                    end
          end
        end
      end
      @mime
    end

    def metadata
      @metadata ||= if content =~ YAML_REGEXP
		      (YAML.load("#{$&}\n") rescue nil).try(:with_indifferent_access) || {}
                    elsif namespace.metadata?
		      {}
		    else
                      super
                    end
    end

    private

    def saved_content
      return nil if new?
      @saved_content ||= Repository.instance.read(self)
    end
  end

  class Tree < Resource
    MIME = MimeMagic.new('inode/directory')

    def namespace
      Namespace.main
    end

    def children(*namespaces)
      @children ||= Repository.instance.children(self).sort_by {|x| "#{x.tree? ? 0 : 1}#{x.name}" }
      namespaces << Namespace.main if namespaces.empty?
      @children.select {|child| namespaces.include?(child.namespace) }
    end

    def mime
      MIME
    end

    def committed(path, tree_version)
      super
      @children = nil
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

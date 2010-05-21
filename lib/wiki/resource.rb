# -*- coding: utf-8 -*-
module Wiki
  # Raised if resource is not found in the repository
  class ObjectNotFound < Routing::NotFound
    def initialize(id)
      super(id)
    end
  end

  class Version < Struct.new(:id, :author, :date, :comment, :parents)
    def self.find(id)
      Repository.instance.find_version(id)
    end

    def self.find!(id)
      find(id) || raise(ObjectNotFound, path)
    end

    def short
      Version.short(id)
    end

    def self.short(id)
      Repository.instance.short_version(id)
    end

    def self.diff(from, to)
      Repository.instance.diff(from, to)
    end

    def to_s
      id
    end

    def ==(other)
      other.to_s == id
    end
  end

  Diff = Struct.new(:from, :to, :patch)

  class Resource
    include Util

    PATH_PATTERN = '[^\s](?:.*[^\s]+)?'
    PATH_REGEXP  = /^#{PATH_PATTERN}$/

    attr_reader :path, :tree_version
    question_reader :current

    def initialize(path, tree_version = nil, current = true)
      @path = path.to_s.cleanpath
      @tree_version = tree_version
      @current = current
      @next_version = @previous_version = @version = nil
    end

    def self.transaction(comment, user = nil, &block)
      raise :empty_comment.t if comment.blank?
      Repository.instance.transaction(comment, user, &block)
    end

    def self.find(path, tree_version = nil)
      path = path.to_s.cleanpath
      check_path(path)
      Repository.instance.find_resource(path, tree_version, Resource == self ? nil : self)
    end

    def self.find!(path, tree_version = nil)
      find(path, tree_version) || raise(ObjectNotFound, path)
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

    def move(destination)
      destination = destination.to_s.cleanpath
      Resource.check_path(destination)
      check_modifiable
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

    def namespace
      if page?
        tmp = name
        Config.namespaces.each do |namespace, prefix|
          return namespace.to_sym if tmp.begins_with?(prefix)
        end
      end
      nil
    end

    def namespace_path(ns = nil)
      n = namespace
      n == ns ? @path : (@path/'..'/(namespace_prefix(ns) + name[namespace_prefix(n).length..-1]))
    end

    def title
      ns = namespace
      if ns
        :"#{ns}_title".t(:name => name[namespace_prefix(ns).length..-1])
      else
        metadata[:title] || name
      end
    end

    def name
      i = path.rindex('/')
      name = i ? path[i+1..-1] : (path.blank? ? Config.root_path : path)
    end

    def safe_name
      name.gsub(/[^\w.\-_]/, '_')
    end

    def committed(path, tree_version)
      @path = path
      @tree_version = tree_version
      @metadata = @version = @next_version = @previous_version = @history = nil
    end

    def metadata
      @metadata ||= Page.find(namespace_path(:metadata), tree_version).try(:metadata) || {}
    end

    protected

    def check_modifiable
      raise 'Tree not current' if !current?
    end

    def namespace_prefix(ns)
      if ns
        Config.namespaces[ns] || raise("Invalid namespace #{ns}")
      else
        ''
      end
    end

    def init_versions
      if !@version && @tree_version
        @previous_version, @version, @next_version = Repository.instance.version(self)
      end
    end

    def self.check_path(path)
      raise :invalid_path.t if (!path.blank? && path !~ PATH_REGEXP) || Config.namespaces.any? {|ns, prefix| prefix == path}
    end
  end

  class Page < Resource
    YAML_MIME = MimeMagic.new('text/x-yaml')
    YAML_REGEXP = /(\A[\-\w_]+:.*?(\r?\n\r?\n|(\r?\n)?\Z))|(\A---\r?\n.*?(\r?\n---|\r?\n\.\.\.|\r?\n\r?\n|(\r?\n)?\Z))/m

    def content(pos = nil, len = nil)
      c = @content || saved_content
      if c
        # Try to encode with the standard wiki encoding utf-8
        # If it is not valid utf-8 we fall back to binary
        c.force_encoding(__ENCODING__)
        c.force_encoding(Encoding::BINARY) if !c.valid_encoding?
        if pos
          c[[[0, pos.to_i].max, c.size].min, [0, len.to_i].max]
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
        if namespace == :metadata
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
                    elsif namespace == :metadata
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
    def children(*namespaces)
      @children ||= Repository.instance.children(self).sort_by {|x| "#{x.tree? ? 0 : 1}#{x.name}" }
      namespaces << nil if namespaces.empty?
      @children.select {|child| namespaces.include?(child.namespace) }
    end

    def mime
      DIRECTORY_MIME
    end

    def committed(path, tree_version)
      super
      @children = nil
    end

    private

    DIRECTORY_MIME = MimeMagic.new('inode/directory')
  end

  class Repository
    include Util
    extend ClassRegistry

    class << self
      attr_writer :instance
      def instance
        @instance ||= find(Config.repository.type).new(Config.repository[Config.repository.type])
      end
    end

    def short_version(version)
      version
    end
  end
end

# -*- coding: utf-8 -*-
module Wiki
  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }

    class FileLoader
      attr_accessor :path

      def initialize(path = nil)
        @path = path
      end

      def cache_id
        path
      end

      def load(name)
        if path
          file = File.join(path, name)
          File.exists?(file) && File.read(file)
        end
      end
    end

    class InlineLoader
      attr_accessor :file

      def initialize(file = nil)
        @file = file
      end

      def cache_id
        file
      end

      def load(name)
        if file
          code, data = File.read(file).split('__END__')
          content = nil
          data.to_s.each_line do |line|
            if line =~ /^@@\s*(.*)/
              content = '' if name == $1
            elsif content
              content << line
            end
          end
          content
        end
      end
    end

    class PluginFileLoader < FileLoader
      def path
        File.dirname(Plugin.current.file) rescue nil
      end
    end

    class PluginInlineLoader < InlineLoader
      def file
        Plugin.current.file rescue nil
      end
    end

    class << self
      attr_reader :cache

      def enable_caching
        @cache = {}
      end

      def with_caching(id)
        return cache[id] if cache && cache[id]
        template = yield
        cache[id] = template if cache
        template
      end

      def loader
        @loader ||= []
      end

      def load(name)
        loader.each do |loader|
          template = loader.load(name)
          return template if template
        end
        nil
      end
    end

    def render(name, opts = {}, &block)
      locals = opts.delete(:locals) || {}
      name = "#{name}.haml"
      haml_opts = HAML_OPTIONS.merge(opts).merge(:filename => name)
      id = [Templates.loader.map {|loader| [loader.class.name, loader.cache_id] }, name, haml_opts].to_s
      engine = Templates.with_caching(id) do
        template = Templates.load(name) || raise(NameError, "Template #{name} not found")
        Haml::Engine.new(template, haml_opts)
      end
      engine.render(self, locals, &block)
    end
  end

end

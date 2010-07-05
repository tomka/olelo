# -*- coding: utf-8 -*-
module Wiki
  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }

    class << self
      attr_reader :cache

      def enable_caching
        @cache = {}
      end

      def paths
        @paths ||= Set.new
      end
    end

    def render(name, opts = {}, &block)
      locals = opts.delete(:locals) || {}
      haml_opts = HAML_OPTIONS.merge(opts).merge(:filename => "#{name}.haml")
      engine = load_template(:haml, name, haml_opts) { |content, opt| Haml::Engine.new(content, opt) }
      engine.render(self, locals, &block)
    end

    private

    def load_template(type, name, opts)
      id = [type,name,opts].to_s
      return Templates.cache[id] if Templates.cache && Templates.cache[id]

      paths = Templates.paths.map {|path| File.join(path, "#{name}.#{type}") }
      path = paths.find {|p| File.exists?(p) }
      raise NameError, "Template #{name} not found" if !path
      content = File.read(path)

      template = yield(content, opts)
      Templates.cache[id] = template if Templates.cache
      template
    end
  end
end

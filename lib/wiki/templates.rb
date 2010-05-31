# -*- coding: utf-8 -*-
module Wiki
  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }

    class << self
      def paths
        @paths ||= Set.new
      end

      def cache
        @cache ||= {}
      end
    end

    def render(name, opts = {})
      output = render_haml(name, opts)
      output = render_haml(:layout, opts) { output } if opts[:layout] != false
      output
    end

    private

    def render_haml(name, opts = {}, &block)
      haml_opts = HAML_OPTIONS.merge(opts[:options] || {}).merge(:filename => "#{name}.haml")
      engine = load_template(:haml, name, haml_opts) { |content, opt| Haml::Engine.new(content, opt) }
      engine.render(self, opts[:locals] || {}, &block)
    end

    def load_template(type, name, opts)
      id = [type,name,opts].to_s
      return Templates.cache[id] if Config.production? && Templates.cache[id]

      paths = Templates.paths.map {|path| File.join(path, "#{name}.#{type}") }
      path = paths.find {|p| File.exists?(p) }
      raise NameError, "Template #{name} not found" if !path
      content = File.read(path)

      template = yield(content, opts)
      Templates.cache[id] = template if Config.production?
      template
    end
  end
end

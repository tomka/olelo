# -*- coding: utf-8 -*-
module Wiki
  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }

    class << self
      lazy_reader(:paths) { [File.join(Config.app_path, 'views')] }
      lazy_reader :template_cache, {}
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
      if Config.production?
        id = [type,name,opts]
        return Templates.template_cache[id] if Templates.template_cache[id]
      end

      paths = Templates.paths.map {|path| File.join(path, "#{name}.#{type}") }
      path = paths.find {|p| File.exists?(p) }
      raise NameError, "Template #{name} not found" if !path
      content = File.read(path)

      template = yield(content, opts)

      if Config.production?
        id = [type,name,opts]
        Templates.template_cache[id] = template
      end

      template
    end
  end
end

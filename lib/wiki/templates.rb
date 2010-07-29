# -*- coding: utf-8 -*-
module Wiki
  module Templates
    HAML_OPTIONS = { :format => :xhtml, :attr_wrapper  => '"', :ugly => true }

    class << self
      attr_reader :cache
      attr_accessor :make_fs

      def enable_caching
        @cache = {}
      end

      def with_caching(id)
        return cache[id] if cache && cache[id]
        template = yield
        cache[id] = template if cache
        template
      end
    end

    def render(name, opts = {}, &block)
      locals = opts.delete(:locals) || {}
      name = "#{name}.haml"
      haml_opts = HAML_OPTIONS.merge(opts).merge(:filename => name)
      fs = Templates.make_fs.call
      id = [fs.fs_id, name, haml_opts].to_s
      engine = Templates.with_caching(id) do
        Haml::Engine.new(fs.read(name), haml_opts)
      end
      engine.render(self, locals, &block)
    end
  end
end

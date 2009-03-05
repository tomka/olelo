module Sinatra
  METHODS = %w(get put post delete head)

  module ComplexPatterns
    METHODS.each do |method|
      class_eval %{
        def #{method}(path, opts, &block)
          if path.respond_to? :to_str
            path, keys = replace_complex_patterns(path, opts)
            super(path, opts) do |*c|
              keys.each_with_index {|k,i| params[k] = c[i] }
              instance_eval(&block)
            end
          else
            super(path, opts, &block)
          end
        end
      }
    end

    private

    def replace_complex_patterns(path, opts = {})
      keys = []
      pat = respond_to?(:patterns) ? self.patterns : {}
      pat = pat.merge(opts[:patterns]) if opts.key?(:patterns)
      path = path.gsub(/:(\w+)/) do
        keys << key = $1.to_sym
        pat.key?(key) ? "(#{pat[key]})" : '([^/?&#\.]+)'
      end
      return /^#{path}$/, keys
    end
  end

  module RouteDumper
    METHODS.each do |method|
      class_eval %{
        def dump_routes
          s = "=== ROUTES ===\n"
          @dump_routes.each do |method,routes|
            s << "  " << method.upcase << ":\n"
            routes.each {|x| s << '    ' << x << "\n" }
          end
          s
        end

        def #{method}(path, opts = {}, &block)
          @dump_routes ||= {}
          routes = @dump_routes['#{method}'] ||= []
          routes << (Regexp === path ? path.source : path.to_s)
          super
        end
      }
    end
  end

  module MultiplePaths
    METHODS.each do |method|
      class_eval %{
        def #{method}(*paths, &block)
          opts = paths.last.is_a?(Hash) ? paths.pop : {}
          paths.each {|path| super(path, opts, &block) }
        end
      }
    end
  end
end

if !Sinatra::Application.respond_to? :patterns
  Sinatra::Application.extend Sinatra::ComplexPatterns
  Sinatra::Application.extend Sinatra::RouteDumper
  Sinatra::Application.extend Sinatra::MultiplePaths
end

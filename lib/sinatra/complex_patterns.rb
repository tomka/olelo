module Sinatra
  module ComplexPatterns
    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval { include InstanceMethods }
      %w(get put post delete head).each do |method|
        base.instance_eval %Q{
          alias #{method}_without_complex_patterns #{method}
          def #{method}(*paths, &block)
            opts = paths.last.is_a?(Hash) ? paths.pop : {}
            paths.each do |path|
              path, keys = replace_complex_patterns(path, opts)
              #{method}_without_complex_patterns(path, opts) do
                captures_to_params(params, keys)
                instance_eval(&block)
              end
            end
          end
        }
      end
    end

    module ClassMethods
      def pattern(key, pattern)
        @patterns ||= {}
        @patterns[key] = pattern
      end

      def replace_complex_patterns(path, opts = {})
        keys = []
        patterns = opts.merge(@patterns)
        path.gsub!(/:(\w+)/) do |key|
          key = $1.to_sym
          keys << key
          patterns.has_key?(key) ? '(' + patterns[key] + ')' : '([^/?&#\.]+)'
        end
        return Regexp.new('^' + path + '$'), keys
      end
    end

    module InstanceMethods
      def captures_to_params(params, keys)
        (0..keys.length-1).each do |i|
          params[keys[i]] = params[:captures][i]
        end
      end
    end

  end
end

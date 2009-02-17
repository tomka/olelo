module Sinatra
  module ComplexPatterns
    def self.included(base)
      return if base.respond_to? :patterns
      puts "included"
      base.extend(ClassMethods)
      base.class_eval do
        include InstanceMethods
        set :patterns, {}  
      end
      %w(get put post delete head).each do |method|
        base.instance_eval { redefine_route_method method }
      end
    end

    module ClassMethods
      private

      def redefine_route_method(method)
        instance_eval %Q{
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

      def replace_complex_patterns(path, opts = {})
        keys = []
        patterns = self.patterns if respond_to?(:patterns)
        patterns.merge!(opts[:patterns]) if opts.key?(:patterns)

        path.gsub!(/:(\w+)/) do |key|
          key = $1.to_sym
          keys << key
          patterns.has_key?(key) ? "(#{patterns[key]})" : '([^/?&#\.]+)'
        end
        return Regexp.new('^' + path + '$'), keys
      end
    end

    module InstanceMethods
      private

      def captures_to_params(params, keys)
        (0..keys.length-1).each do |i|
          params[keys[i]] = params[:captures][i]
        end
      end
    end

  end
end

class Sinatra::Base
  include Sinatra::ComplexPatterns
end


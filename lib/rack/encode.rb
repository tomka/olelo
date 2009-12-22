module Rack
  class Encode
    if RUBY_VERSION > '1.9'
      def initialize(app, opts = {})
        @app = app
        @encoding = Encoding.find(opts[:encoding] || 'utf-8')
      end

      def call(env)
        @app.call(encode(env))
      end

      private

      def encode(x)
        case x
        when Hash
          x.each { |k,v| x[k] = encode(v) }
        when Array
          x.each_with_index {|v,i| x[i] = encode(v) }
        when String
          if x.encoding != @encoding
            x = x.dup if x.frozen?
            x.force_encoding(@encoding)
          else
            x
          end
        else
          x
        end
      end
    else
      def initialize(app, opts = {})
        @app = app
      end

      def call(env)
        @app.call(env)
      end
    end
  end
end

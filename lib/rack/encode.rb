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
          result = {}
          x.each { |k, v| result[encode(k)] = encode(v) }
          result
        when Array
          x.map {|v| encode(v) }
        when String
          x.encoding != @encoding ? x.dup.force_encoding(@encoding) : x
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

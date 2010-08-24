module Rack
  class ForceEncoding
    def initialize(app, encoding = Encoding::UTF_8)
      @app = app
      @encoding = encoding
    end

    def call(env)
      request = Rack::Request.new(env)
      encode(env)
      encode(request.params)
      @app.call(env)
    end

    private

    def encode(x)
      case x
      when Hash
        x.each { |k,v| x[k] = encode(v) }
      when Array
        x.each_with_index {|v,i| x[i] = encode(v) }
      when String
        # Try to force encoding and revert to old encoding if this doesn't work
        encoding = x.encoding
        if encoding != @encoding
          x = x.dup if x.frozen?
          x.force_encoding(@encoding)
          x.force_encoding(encoding) if !x.valid_encoding?
          x
        else
          x
        end
      else
        x
      end
    end
  end
end

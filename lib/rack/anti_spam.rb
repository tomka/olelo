module Rack
  class AntiSpam
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Request.new(env)
      if request.post?
        if spam?(request)
          response = Response.new
          response.status = 403
          response.write 'Stop spamming!'
          return response.finish
        end
      end
      @app.call(env)
    end

    private

    def spam?(request)
      data = request.params.values.join("\n")

      # More than 30% URLS
      size = 0
      data.scan(/((https?|ftps?):\/\/\S+?)(?=([,.?!:;"'\)])?(\s|$))/) { size += $1.size }
      return true if size.to_f / data.size > 0.3

      # Add more tests if necessary

      false
    end
  end
end

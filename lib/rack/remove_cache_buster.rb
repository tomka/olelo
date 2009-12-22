module Rack
  class RemoveCacheBuster
    def initialize(app, opts = {})
      @app = app
      @buster = opts[:buster] || '_'
    end

    def call(env)
      request = Request.new(env)
      if request.GET.include?(@buster)
        request.GET.delete(@buster)
        env['QUERY_STRING'] = env["rack.request.query_string"] = Rack::Utils.build_query(request.GET)
      end
      @app.call(env)
    end
  end
end

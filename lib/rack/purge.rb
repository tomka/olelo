module Rack
  class Purge
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Request.new(env)
      if request.GET.key?('purge')
        request.GET.delete('purge')
        env['QUERY_STRING'] = Rack::Utils.build_query(request.GET)
        env['HTTP_PRAGMA'] = 'no-cache'
        env['HTTP_CACHE_CONTROL'] ||= 'no-cache'
      end
      @app.call(env)
    end
  end
end

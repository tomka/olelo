# -*- coding: utf-8 -*-
module Rack
  class Purge
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Request.new(env)
      if request.GET.key?('purge')
        request.GET.delete('purge')
        env.update('QUERY_STRING' => Rack::Utils.build_query(request.GET),
                   'HTTP_PRAGMA' => 'no-cache',
                   'HTTP_CACHE_CONTROL' => 'no-cache',
                   'rack-cache.allow_revalidate' => true,
                   'rack-cache.allow_reload' => true)
      end
      @app.call(env)
    end
  end
end

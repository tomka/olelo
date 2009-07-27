require 'rack/cache'

module Rack
  class Cache::Purge
    def initialize(app)
      @app = app
    end

    def call(env)
      request  = Request.new(env)
      cap = env['rack.capabilities']
      if request.GET.key?('purge') && cap && cache = cap.find(Rack::Cache::Context)
        request.GET.delete('purge')
        env['QUERY_STRING'] = Rack::Utils.build_query(request.GET)
        response = cache.metastore.lookup(request, cache.entitystore)
        if response
          cache.metastore.purge(cache.metastore.cache_key(request))
          cache.entitystore.purge(response.headers['X-Content-Digest'])
        end
      end
      @app.call(env)
    end
  end
end

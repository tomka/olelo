module Rack
  class BanIP
    def initialize(app, options)
      @app = app
      @file = options[:file]
      @list = nil
    end

    def call(env)
      if %w(POST PUT DELETE).include? env['REQUEST_METHOD']
        request  = Request.new(env)
        if ban_list.include?(request.ip)
          response = Response.new
          response.status = 403
          response.write 'Your IP has been banned.'
          return response.finish
        end
      end
      @app.call(env)
    end

    private

    def ban_list
      return [] if !::File.exists?(@file)
      if !@list || @time < ::File.mtime(@file)
        @time = ::File.mtime(@file)
        @list = ::File.read(@file).split(/\s+/)
      end
      @list
    end
  end
end

# -*- coding: utf-8 -*-
require 'socket'

module Rack
  class ReverseIP
    def initialize(app)
      @app = app
    end

    def call(env)
      request  = Request.new(env)
      env['rack.hostbyip'] = Socket.gethostbyaddr(request.ip.split('.').map {|x| x.to_i }.pack('CCCC')).first rescue nil
      @app.call(env)
    end
  end
end

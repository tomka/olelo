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
        if banned?(request.ip)
          response = Response.new
          response.status = 403
          response.write 'Your IP has been banned.'
          return response.finish
        end
      end
      @app.call(env)
    end

    private

    def banned?(ip)
      return false if !::File.exists?(@file)
      if !@list || @time < ::File.mtime(@file)
        @time = ::File.mtime(@file)
        @list = ::File.read(@file).split("\n").
          map {|line| line.strip }.select{|line| !line.empty? }
        @list.map! do |line|
          range = line.split(/\s*-\s*/)
          range.size == 1 ? parse_ip(line) : (parse_ip(range[0]) .. parse_ip(range[1]))
        end
      end
      ip = parse_ip(ip)
      @list.any? do |entry|
        Range === entry ? entry.include?(ip) : entry == ip
      end
    end

    def parse_ip(ip)
      n = ip.split('.')
      (n[0].to_i << 24) | (n[1].to_i << 16) | (n[2].to_i << 8) | n[3].to_i
    end
  end
end

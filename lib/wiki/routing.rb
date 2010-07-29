# -*- coding: utf-8 -*-
module Wiki
  module Routing
    class NotFound < NameError
      def initialize(path)
        super(:not_found.t(:id => path), path)
      end

      def status
        :not_found
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval { include Hooks }
    end

    attr_reader :params, :response, :request, :env

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      @env      = env
      @request  = Rack::Request.new(env)
      @response = Rack::Response.new
      @params = @original_params = @request.params.with_indifferent_access

      # Interpret everything as utf-8
      if ''.respond_to? :encoding
        encode(@env)
        encode(@params)
      end

      catch(:forward) do
        with_hooks(:request) { perform! }
        status, header, body = @response.finish
        return [status, header, @request.head? ? [] : body]
      end
      @app ? @app.call(env) : error!(NotFound.new(@request.path_info))
    end

    def halt(*response)
      throw :halt, response.length == 1 ? response.first : response
    end

    def redirect(uri); throw :redirect, uri end
    def pass; throw :pass end
    def forward; throw :forward end

    private

    def encode(x)
      case x
      when Hash
        x.each { |k,v| x[k] = encode(v) }
      when Array
        x.each_with_index {|v,i| x[i] = encode(v) }
      when String
        if x.encoding != __ENCODING__
          x = x.dup if x.frozen?
          x.force_encoding(__ENCODING__)
        else
          x
        end
      else
        x
      end
    end

    def error!(ex)
      @response.status = Rack::Utils.status_code(ex.try(:status) || :internal_server_error)
      @response.body   = [ex.message]
      invoke_hook(ex.class, ex).join
    rescue => ex
      @logger.error(ex) if @logger
      %{<span class="error">#{escape_html ex.message}</span>}
    end

    def perform!
      result = catch(:halt) do
        uri = catch(:redirect) do
          with_hooks(:routing) { route! }
        end
        @response.redirect uri
        nil
      end

      return if !result
      if result.respond_to?(:to_str)
        @response.body = [result]
      elsif result.respond_to?(:to_ary)
        result = result.to_ary
        status = result.first
        if Fixnum === status || Symbol === status
          @response.status = Rack::Utils.status_code(status)
          if result.length == 3
            status, headers, body = result
            @response.body = body if body
            @response.headers.merge!(headers) if headers
          elsif result.length == 2
            @response.body = result.last
          else
            raise TypeError, "#{result.inspect} not supported"
          end
        else
          @response.body = result
        end
      elsif result.respond_to?(:each)
        @response.body = result
      elsif Fixnum === result || Symbol === result
        @response.status = Rack::Utils.status_code(result)
      end
    end

    def route!
      path = unescape(@request.path_info)
      method = @request.request_method
      routes = self.class.routes[method]
      routes.each do |name, pattern, keys|
        if match = pattern.match(path)
          captures = match.captures.to_a
          params =
            if keys.any?
              keys.zip(captures).inject({}) do |hash,(k,v)|
                hash[k] = v
                hash
              end
            elsif captures.any?
              {'captures' => captures}
            else
              {}
            end
          @params = @original_params.merge(params)
          catch(:pass) do
            with_hooks(:action, method.downcase.to_sym, name) do
              halt send("#{method} #{name}")
            end
          end
        end
      end

      raise NotFound, path
    rescue ::Exception => ex
      halt error!(ex)
    end

    module ClassMethods
      def routes
        @routes ||= {}
      end

      def patterns(patterns = nil)
        @patterns ||= Hash.with_indifferent_access
        patterns ? @patterns.merge!(patterns) : @patterns
      end

      def get(*paths, &block);    add_route(['GET', 'HEAD'], paths, &block) end
      def put(*paths, &block);    add_route('PUT',    paths, &block) end
      def post(*paths, &block);   add_route('POST',   paths, &block) end
      def delete(*paths, &block); add_route('DELETE', paths, &block) end

      def dump_routes
        s = "=== ROUTES ===\n"
        routes.each do |method,list|
          s << "  #{method}:\n"
          list.each {|x,y| s << "    #{x} -> #{y.source}\n" }
        end
        s
      end

      private

      def compile_route(path, patterns)
        keys = []
        if path.respond_to? :to_str
          pattern = Regexp.escape(path).gsub(/:(\w+)|\\\?/) do |match|
            if match == '\?'
              '?'
            else
              keys << $1
              patterns.key?($1) ? "(#{patterns[$1]})" : "([^/?&#\.]+)"
            end
          end
          [path, /^#{pattern}$/, keys]
        elsif path.respond_to? :match
          [path.source, path, keys]
        else
          raise TypeError, path
        end
      end

      def add_route(methods, paths, &block)
        paths = [*paths]
        patterns = self.patterns.merge(Hash === paths.last ? paths.pop : {})
        paths.each do |path|
          path, pattern, keys = compile_route(path, patterns)
          [*methods].each do |m|
            name = "#{m} #{path}"
            if method_defined?(name)
              redefine_method(name, &block)
            else
              define_method(name, &block)
              (routes[m] ||= []) << [path, pattern, keys]
            end
          end
        end
      end

    end
  end
end

module Olelo
  module Routing
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

      catch(:forward) do
        with_hooks(:request) { perform! }
        status, header, body = response.finish
        return [status, header, request.head? ? [] : body]
      end

      @app ? @app.call(env) : error!(NotFound.new(@request.path_info))
    end

    def halt(*response)
      throw :halt, response.length == 1 ? response.first : response
    end

    def redirect(uri)
      throw :redirect, uri
    end

    def pass
      throw :pass
    end

    def forward
      throw :forward
    end

    private

    def error!(ex)
      response.status = Rack::Utils.status_code(ex.try(:status) || :internal_server_error)
      response.body   = [ex.message]
      invoke_hook(ex.class, ex).join
    end

    def perform!
      result = catch(:halt) do
        uri = catch(:redirect) do
          with_hooks(:routing) { route! }
        end
        response.redirect uri
        nil
      end

      return if !result
      if result.respond_to?(:to_str)
        response.body = [result]
      elsif result.respond_to?(:to_ary)
        result = result.to_ary
        if result.length == 2 && Symbol === result.first
          response.status = Rack::Utils.status_code(result.first)
          response.body = result.last
        else
          response.body = result
        end
      elsif result.respond_to?(:each)
        response.body = result
      elsif Symbol === result
        response.status = Rack::Utils.status_code(result)
      else
        raise TypeError, "#{result.inspect} not supported"
      end
    end

    def route!
      path = unescape(request.path_info)
      method = request.request_method
      self.class.router[method].find(path) do |name, params|
        @params = @original_params.merge(params)
        catch(:pass) do
          with_hooks(:action, method.downcase.to_sym, name) do
            halt send("#{method} #{name}")
          end
        end
      end if self.class.router[method]
      raise NotFound, path
    rescue ::Exception => ex
      halt error!(ex)
    end

    class Router
      SYNTAX = {
        '\(' => '(?:', '\)' => ')?',
        '\{' => '(?:', '\}' => ')',
        '\|' => '|'
      }

      include Enumerable

      def initialize
        @routes = []
      end

      def find(path)
        each do |name, pattern, keys|
          if match = pattern.match(path)
            params = {}
            keys.zip(match.captures.to_a).each {|k, v| params[k] = v if !v.blank? }
            yield(name, params)
          end
        end
      end

      def each(&block)
        @routes.each(&block)
      end

      def add(path, patterns = {})
        pattern = Regexp.escape(path)
        SYNTAX.each {|k,v| pattern.gsub!(k, v) }
        keys = []
        pattern.gsub!(/:(\w+)/) do
          keys << $1
          patterns.key?($1) ? "(#{patterns[$1]})" : "([^/?&#\.]+)"
        end
        @routes << [path, /^#{pattern}$/, keys]
      end
    end

    module ClassMethods
      def router
        @router ||= {}
      end

      def patterns(patterns = nil)
        @patterns ||= Hash.with_indifferent_access
        patterns ? @patterns.merge!(patterns) : @patterns
      end

      def get(path, patterns = {}, &block)
        add_route('GET',  path, patterns, &block)
        add_route('HEAD', path, patterns, &block)
      end

      def put(path, patterns = {}, &block)
        add_route('PUT', path, patterns, &block)
      end

      def post(path, patterns = {}, &block)
        add_route('POST', path, patterns, &block)
      end

      def delete(path, patterns = {}, &block)
        add_route('DELETE', path, patterns, &block)
      end

      private

      def add_route(method, path, patterns = {}, &block)
        name = "#{method} #{path}"
        if method_defined?(name)
          redefine_method(name, &block)
        else
          define_method(name, &block)
          (router[method] ||= Router.new).add(path, self.patterns.merge(patterns))
        end
      end
    end
  end
end

# -*- coding: utf-8 -*-
require 'wiki/utils'

module Wiki
  module Routing
    class NotFound < NameError
      def status; 404 end
    end

    def self.included(base)
      base.extend(ClassMethods)
      base.class_eval do
        include Hooks
        include InstanceMethods
      end
    end

    module InstanceMethods
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
          perform!
          status, header, body = @response.finish
          return [status, header, @request.head? ? [] : body]
        end
        @app ? @app.call(env) : handle_error(NotFound.new('Sub application not set'))
      end

      def halt(*response)
        response = response.first if response.length == 1
        throw :halt, response
      end

      def redirect(uri); throw :redirect, uri end
      def pass; throw :pass end
      def forward; throw :forward end

      private

      def handle_error(ex)
        @response.status = ex.try(:status) || 500
        @response.body   = [ex.message]
        safe_output do
          invoke_hook(ex.class, ex).to_s
        end
      end

      def perform!
        result = catch(:halt) do
          uri = catch(:redirect) do
            halt(dispatch!)
          end
          @response.status = 302
          @response['Location'] = Wiki.uri_escape(uri).gsub('%2F', '/').gsub('%3A', ':')
          nil
        end

        return if !result
        if result.respond_to?(:to_str)
          @response.body = [result]
        elsif result.respond_to?(:to_ary)
          result = result.to_ary
          if Fixnum === result.first
            if result.length == 3
              @response.status, headers, body = result
              @response.body = body if body
              @response.headers.merge!(headers) if headers
            elsif result.length == 2
              @response.status = result.first
              @response.body   = result.last
            else
              raise TypeError, "#{result.inspect} not supported"
            end
          else
            @response.body = result
          end
        elsif result.respond_to?(:each)
          @response.body = result
        elsif (100...599) === result
          @response.status = result
        end
      end

      def dispatch!
        route!
      rescue ::Exception => ex
        handle_error(ex)
      end

      def route!
        invoke_hook(:before_routing)

        path = Wiki.uri_unescape(@request.path_info)
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

        raise NotFound, :not_found.t(:path => path)
      end
    end

    module ClassMethods
      lazy_reader :routes, {}

      def patterns(patterns = nil)
        @patterns ||= Hash.with_indifferent_access
        return @patterns if !patterns
        @patterns.merge!(patterns)
      end

      def get(*paths, &block);    add_route(['GET', 'HEAD'], paths, &block) end
      def put(*paths, &block);    add_route('PUT',    paths, &block) end
      def post(*paths, &block);   add_route('POST',   paths, &block) end
      def delete(*paths, &block); add_route('DELETE', paths, &block) end
      def head(*paths, &block);   add_route('HEAD',   paths, &block) end

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

      def add_route(methods, paths, opts={}, &block)
        opts = paths.last.is_a?(Hash) ? paths.pop : {}
        paths.each do |path|
          patterns = opts[:patterns] ? self.patterns.merge(opts[:patterns]) : self.patterns
          path, pattern, keys = compile_route(path, patterns)
          [methods].flatten.each do |m|
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

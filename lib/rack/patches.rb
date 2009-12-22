# -*- coding: utf-8 -*-
require 'rack'
require 'rack/session/abstract/id'
require 'socket'
require 'securerandom'

class Rack::Request
  remove_method :params
  remove_method :ip

  # FIXME: Rack ignores post data for put requests
  def params
    self.GET.update(self.POST)
  rescue EOFError => ex
    self.GET
  end

  # FIXME: Rack bug with HTTP_X_FORWARDED_FOR
  def ip
    if addr = @env['HTTP_X_FORWARDED_FOR']
      addr.split(',').find {|x| x =~ /[\d\.]+/ }.strip
    else
      @env['REMOTE_ADDR']
    end
  end

  # Remote host name
  def remote_host
    @remote_host ||= Socket.gethostbyaddr(ip.split('.').map(&:to_i).pack('C*')).first rescue nil
  end

  # No caching for this request?
  def no_cache?
    env['HTTP_PRAGMA'] == 'no-cache' || env['HTTP_CACHE_CONTROL'].to_s.include?('no-cache')
  end
end

class Rack::Session::Abstract::ID
  # FIXME: Response buffering problem
  # this is fixed in github repository, but not released yet
  def commit_session(env, status, headers, body)
    session = env['rack.session']
    options = env['rack.session.options']
    session_id = options[:id]

    if not session_id = set_session(env, session_id, session, options)
      env["rack.errors"].puts("Warning! #{self.class.name} failed to save session. Content dropped.")
      [status, headers, body]
    elsif options[:defer] and not options[:renew]
      env["rack.errors"].puts("Defering cookie for #{session_id}") if $VERBOSE
      [status, headers, body]
    else
      cookie = Hash.new
      cookie[:value] = session_id
      cookie[:expires] = Time.now + options[:expire_after] unless options[:expire_after].nil?
      response = Rack::Response.new([], status, headers)
      response.body = body # FIXME: This is the fix
      response.set_cookie(@key, cookie.merge(options))
      response.to_a
    end
  end

  # FIXME: Secure random
  # http://rack.lighthouseapp.com/projects/22435-rack/tickets/85-securerandom-for-secure-key-generation
  def generate_sid
    SecureRandom.hex
  end
end

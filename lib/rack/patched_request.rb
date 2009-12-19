# -*- coding: utf-8 -*-
require 'rack'

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
      addr.split(',').first.strip
    else
      @env['REMOTE_ADDR']
    end
  end

  # No caching for this request?
  def no_cache?
    env['HTTP_PRAGMA'] == 'no-cache' || env['HTTP_CACHE_CONTROL'].to_s.include?('no-cache')
  end
end

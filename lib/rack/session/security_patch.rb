# -*- coding: utf-8 -*-
require 'rack/session/abstract/id'
autoload 'SecureRandom', 'securerandom'

class Rack::Session::Abstract::ID
  def generate_sid
    SecureRandom.hex
  end
end

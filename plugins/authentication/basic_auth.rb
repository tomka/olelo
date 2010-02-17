author      'Daniel Mendler'
description 'HTTP basic authentication'
require 'rack/auth/basic'

class Wiki::Application
  hook(:auto_login) do
    if params[:auth] && !user
      auth = Rack::Auth::Basic::Request.new(env)
      unauthorized if !auth.provided?
      halt :bad_request if !auth.basic?
      user = User.authenticate(auth.credentials[0], auth.credentials[1]) rescue nil
      unauthorized if !user
      self.user = user
    end
  end

  private

  def unauthorized
    response['WWW-Authenticate'] = 'Basic realm="Wiki"'
    halt :unauthorized
  end
end

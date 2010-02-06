author      'Daniel Mendler'
description 'HTTP basic authentication'
require 'rack/auth/basic'

class Wiki::App
  def unauthorized
    response['WWW-Authenticate'] = 'Basic realm="Wiki"'
    halt 401
  end

  hook(:auto_login) do
    if !session[:user] && params[:auth]
      auth = Rack::Auth::Basic::Request.new(env)
      unauthorized if !auth.provided?
      halt 400 if !auth.basic?
      user = User.authenticate(auth.credentials[0], auth.credentials[1]) rescue nil
      unauthorized if !user
      session[:user] = @user = user
    end
  end
end

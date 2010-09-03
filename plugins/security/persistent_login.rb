description 'Persistent login'
require     'pstore'
require     'securerandom'

class Olelo::Application
  TOKEN_LIFETIME = 24*60*60*365
  TOKEN_NAME = 'olelo.token'

  def login_tokens
    @login_tokens ||= PStore.new(File.join(Olelo::Config.tmp_path, 'tokens.pstore'))
  end

  def get_login_token(token)
    login_tokens.transaction(true) do |store|
      store[token] && store[token][0]
    end
  end

  def set_login_token(token, value)
    login_tokens.transaction do |store|
      store[token] = [value, Time.now]
      clean_login_tokens(store)
    end
  end

  def delete_login_token(token)
    login_tokens.transaction do |store|
      store.delete(token)
      clean_login_tokens(store)
    end
  end

  def clean_login_tokens(store)
    store.roots.each do |key|
      store.delete(key) if store[key][1] + TOKEN_LIFETIME < Time.now
    end
  end

  hook :auto_login do
    if !User.current
      token = request.cookies[TOKEN_NAME]
      if token
        user = get_login_token(token)
        User.current = User.find(user) if user
      end
    end
  end

  hook :layout do |name, doc|
    if name == :login
      doc.css('#tab-login button[type=submit]').before(
        %{<input type="checkbox" name="persistent" id="persistent" value="1"/>
          <label for="persistent">#{escape_html :persistent_login.t}</label><br/>})
    end
  end

  after :action do |method, path|
    if path == '/login'
      if User.logged_in? && params[:persistent]
        token = SecureRandom.hex
        response.set_cookie(TOKEN_NAME, :value => token, :expires => Time.now + TOKEN_LIFETIME)
        set_login_token(token, User.current.name)
      end
    elsif path == '/logout'
      token = request.cookies[TOKEN_NAME]
      delete_login_token(token)
      response.delete_cookie(TOKEN_NAME)
    end
  end
end

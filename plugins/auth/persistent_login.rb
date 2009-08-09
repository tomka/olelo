author      'Daniel Mendler'
description 'Persistent login'
require     'pstore'

class Wiki::App
  TOKEN_LENGTH = 64
  TOKEN_LIFETIME = 24*60*60*365
  TOKEN_NAME = 'git_wiki_token'

  lazy_reader(:login_tokens) { PStore.new(File.join(Wiki::Config.cache, 'tokens.pstore')) }

  def get_login_token(token)
    login_tokens.transaction(true) do |store|
      store[token] && store[token][0]
    end
  end

  def set_login_token(token, value)
    login_tokens.transaction(false) do |store|
      store[token] = [value, Time.now]
      clean_login_tokens(store)
    end
  end

  def delete_login_token(token)
    login_tokens.transaction(false) do |store|
      store.delete(token)
      clean_login_tokens(store)
    end
  end

  def clean_login_tokens(store)
    store.roots.each do |key|
      store.delete(key) if store[key][1] + TOKEN_LIFETIME < Time.now
    end
  end

  add_hook(:auto_login) do
    token = request.cookies[TOKEN_NAME]
    if token
      user = get_login_token(token)
      session[:user] = @user = User.find(user) if user
    end
  end

  add_hook(:after_action) do |method, path|
    if path == '/login'
      if !@user.anonymous?
        ch = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
        token = ''
        1.upto(TOKEN_LENGTH) { |i| token << ch[rand(ch.size-1)] }
        response.set_cookie(TOKEN_NAME, :value => token, :expires => Time.now + TOKEN_LIFETIME)
        set_login_token(token, @user.name)
      end
    elsif path == '/logout'
      token = request.cookies[TOKEN_NAME]
      delete_login_token(token)
      response.delete_cookie(TOKEN_NAME)
    end
  end
end

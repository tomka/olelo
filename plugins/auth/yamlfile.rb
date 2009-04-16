Wiki::Plugin.define 'auth/yamlfile' do
  require 'yaml/store'
  require 'digest'

  Wiki::User.define_service(:yamlfile) do
    include Wiki::Utils

    def initialize
      @store ||= begin
        FileUtils.mkdir_p File.dirname(Wiki::Config.auth.store), :mode => 0755
        YAML::Store.new(Wiki::Config.auth.store)
      end
    end

    def authenticate(name, password)
      @store.transaction(true) do |store|
        user = store[name]
        forbid('Wrong username or password' => !user || user['password'] != crypt(password))
        return Wiki::User.new(name, user['email'], false)
      end
    end

    def create(user, password)
      @store.transaction do |store|
        forbid('User already exists' => store[user.name])
        store[user.name] = {
          'email' => user.email,
          'password' => crypt(password)
        }
      end
    end

    def update(user)
      @store.transaction do |store|
        forbid('User not found' => !store[user.name])
        store[user.name]['email'] = user.email
      end
    end

    def change_password(user, oldpassword, password)
      @store.transaction do |store|
        forbid('User not found' => !store[user.name])
        forbid('Password is wrong' => crypt(oldpassword) != store[user.name]['password'])
        store[user.name]['password'] = crypt(password)
      end
    end

    private

    def crypt(s)
      s.blank? ? s : Digest::SHA256.hexdigest(s)
    end
  end
end

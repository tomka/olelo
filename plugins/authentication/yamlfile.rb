author      'Daniel Mendler'
description 'YAML based user storage'
require     'yaml/store'
require     'digest'

User.define_service(:yamlfile) do
  def initialize
    FileUtils.mkdir_p File.dirname(Config.auth.store), :mode => 0755
    @store = YAML::Store.new(Config.auth.store)
  end

  def find(name)
    @store.transaction(true) do |store|
      user = store[name]
      user && User.new(name, user['email'], user['groups'])
    end
  end

  def authenticate(name, password)
    @store.transaction(true) do |store|
      user = store[name]
      forbid('Wrong username or password' => !user || user['password'] != crypt(password))
      User.new(name, user['email'], user['groups'])
    end
  end

  def create(user, password)
    @store.transaction do |store|
      forbid('User already exists' => store[user.name])
      store[user.name] = {
        'email' => user.email,
        'password' => crypt(password),
	'groups' => user.groups
      }
    end
  end

  def update(user)
    @store.transaction do |store|
      forbid('User not found' => !store[user.name])
      store[user.name]['email'] = user.email
      store[user.name]['groups'] = user.groups
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

author      'Daniel Mendler'
description 'YAML based user storage'

module ::YAML
  autoload 'Store', 'yaml/store'
end

User.define_service(:yamlfile) do
  def initialize
    FileUtils.mkdir_p File.dirname(Config.auth.store), :mode => 0755
    @store = ::YAML::Store.new(Config.auth.store)
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
      raise AuthenticationError, 'Wrong username or password' if !user || user['password'] != crypt(password)
      User.new(name, user['email'], user['groups'])
    end
  end

  def create(user, password)
    @store.transaction do |store|
      raise RuntimeError, 'User already exists' if store[user.name]
      store[user.name] = {
        'email' => user.email,
        'password' => crypt(password),
	'groups' => user.groups
      }
    end
  end

  def update(user)
    @store.transaction do |store|
      raise NameError, "User #{user.name} not found" if !store[user.name]
      store[user.name]['email'] = user.email
      store[user.name]['groups'] = user.groups
    end
  end

  def change_password(user, oldpassword, password)
    @store.transaction do |store|
      Wiki.check do |errors|
        errors << 'User not found' if !store[user.name]
        errors << 'Password is wrong' if crypt(oldpassword) != store[user.name]['password']
      end
      store[user.name]['password'] = crypt(password)
    end
  end

  private

  def crypt(s)
    s.blank? ? s : Wiki.sha256(s)
  end
end

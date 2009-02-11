require 'wiki/entry'
require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  class User < Entry
    include Utils

    attr_accessor :email
    attr_reader :password
    transient :anonymous

    def anonymous?; @anonymous; end

    def change_password(oldpassword, password, confirm)
      forbid('Passwords do not match' => password != confirm,
             'Password is wrong'      => @password != User.crypt(oldpassword))
      @password = User.crypt(password)
    end

    def author
      "#{@name} <#{@email}>"
    end

    def save
      forbid(
        'E-Mail is invalid' => @email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
        'Name is invalid'   => @name !~ /[\w.\-+_]+/,
        'Password is empty' => @password.blank?,
        'Anonymous'         => anonymous?
      )
      super
    end

    def self.anonymous(ip)
      User.new(ip, nil, "anonymous@#{ip}", true)
    end

    def self.authenticate(name, password)
      user = find(name)
      forbid('Wrong username or password' => !user || user.password != User.crypt(password))
      user
    end

    def self.create(name, password, confirm, email)
      forbid('Passwords do not match' => password != confirm,
             'User already exists'    => find(name))
      User.new(name, password, email, false).save
    end

    private

    def initialize(name, password, email, anonymous)
      super(name)
      @email = email
      @anonymous = anonymous
      @password = User.crypt(password)
    end

    def self.crypt(s)
      s.blank? ? s : Digest::SHA256.hexdigest(s)
    end
  end
end

require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  class User
    include Utils

    attr_reader :name
    attr_accessor :email
    question_accessor :anonymous

    def initialize(name, email, anonymous)
      @name = name
      @email = email
      @anonymous = anonymous
    end

    def change_password(oldpassword, password, confirm)
      validate_password(password, confirm)
      User.service.change_password(self, oldpassword, password)
    end

    def author
      "#{@name} <#{@email}>"
    end

    def modify(&block)
      copy = dup
      block.call(copy)
      validate
      User.service.update(copy)
      instance_variables.each do |name|
        instance_variable_set(name, copy.instance_variable_get(name))
      end
    end

    def validate
      forbid('E-Mail is invalid' => email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
             'Name is invalid'   => name !~ /[\w.\-+_]+/,
             'Anonymous'         => anonymous?)
    end

    static do
      def validate_password(password, confirm)
        forbid('Passwords do not match' => password != confirm,
               'Password is empty' => password.blank?)
      end
    end

    @services = {}

    class<< self
      def define_service(name, &block)
        service = Class.new
        service.class_eval(&block)
        @services[name.to_s] = service
      end

      def service
        @service ||= begin
                       serv = @services[Config.auth.service]
                       raise(ArgumentError, "Authentication service #{Config.auth.service} not found") if !serv
                       serv.new
                     end
      end

      def anonymous(ip)
        new(ip, "anonymous@#{ip}", true)
      end

      def authenticate(name, password)
        service.authenticate(name, password)
      end

      def create(name, password, confirm, email)
        validate_password(password, confirm)
        user = User.new(name, email, false )
        user.validate
        service.create(user, password)
        user
      end
    end

  end
end

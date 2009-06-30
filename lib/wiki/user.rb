require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  class User
    attr_reader :name
    attr_accessor :email
    question_accessor :anonymous

    def initialize(name, email, anonymous)
      @name = name
      @email = email
      @anonymous = anonymous
    end

    def change_password(oldpassword, password, confirm)
      User.validate_password(password, confirm)
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
      forbid(:invalid_email.t => email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i,
             :invalid_name.t  => name !~ /[\w.\-+_]+/,
             :anonymous.t     => anonymous?)
    end

    @services = {}

    class<< self
      def validate_password(password, confirm)
        forbid(:passwords_do_not_match.t => password != confirm,
               :empty_password.t => password.blank?)
      end

      def define_service(name, &block)
        service = Class.new
        service.class_eval(&block)
        @services[name.to_s] = service
      end

      def service
        @service ||= begin
                       serv = @services[Config.auth.service]
                       raise(RuntimeError, "Authentication service #{Config.auth.service} not found") if !serv
                       serv.new
                     end
      end

      def anonymous(request)
        ip = request.ip || 'unknown-ip'
        name = request.env['rack.hostbyip'] ? "#{request.env['rack.hostbyip']} (#{ip})" : ip
        new(name, "anonymous@#{ip}", true)
      end

      def find(name)
        service.find(name)
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

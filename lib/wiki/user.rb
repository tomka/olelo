# -*- coding: utf-8 -*-
require 'wiki/utils'
require 'wiki/extensions'

module Wiki
  class User
    attr_reader :name, :groups
    attr_accessor :email

    def anonymous?
      @groups.include? 'anonymous'
    end

    def initialize(name, email, groups = [])
      @name = name
      @email = email
      @groups = groups || []
      @groups << 'user' if !anonymous?
    end

    def change_password(oldpassword, password, confirm)
      User.validate_password(password, confirm)
      User.service.change_password(self, oldpassword, password)
    end

    def to_git_user
      Gitrb::User.new(name, email)
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
             :invalid_name.t  => name !~ /[\w.\-+_]+/)
    end

    @services = {}

    class NullService
      def method_missing(name, *args)
        raise StandardError, "Authentication service does not support #{name}"
      end
    end

    class<< self
      def validate_password(password, confirm)
        forbid(:passwords_do_not_match.t => password != confirm,
               :empty_password.t => password.blank?)
      end

      def define_service(name, &block)
        service = Class.new(NullService)
        service.class_eval(&block)
        @services[name.to_s] = service
      end

      lazy_reader :service do
        serv = @services[Config.auth.service]
        raise(RuntimeError, "Authentication service #{Config.auth.service} not found") if !serv
        serv.new
      end

      def anonymous(request)
        ip = request.ip || 'unknown-ip'
        name = request.env['rack.hostbyip'] ? "#{request.env['rack.hostbyip']} (#{ip})" : ip
        new(name, "anonymous@#{ip}", %w(anonymous))
      end

      def find(name)
        service.find(name)
      end

      def authenticate(name, password)
        service.authenticate(name, password)
      end

      def create(name, password, confirm, email)
        validate_password(password, confirm)
        user = new(name, email)
        user.validate
        service.create(user, password)
        user
      end
    end

  end
end

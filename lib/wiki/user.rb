# -*- coding: utf-8 -*-
module Wiki
  class AuthenticationError < RuntimeError
  end

  class User
    include Util
    attr_reader :name, :groups
    attr_accessor :email

    def anonymous?
      @groups.include? 'anonymous'
    end

    def initialize(name, email, groups = nil)
      @name = name
      @email = email
      @groups = groups.to_a
      @groups << 'user' if !anonymous?
    end

    def change_password(oldpassword, password, confirm)
      User.validate_password(password, confirm)
      service.change_password(self, oldpassword, password)
    end

    def modify(&block)
      copy = dup
      block.call(copy)
      validate
      service.update(copy)
      instance_variables.each do |name|
        instance_variable_set(name, copy.instance_variable_get(name))
      end
    end

    def validate
      check do |errors|
        errors << :invalid_email.t if email !~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
        errors << :invalid_name.t  if name !~ /[\w.\-+_]+/
      end
    end

    class Service
      include Util
      extend ClassRegistry

      def method_missing(name, *args)
        raise NotImplementedError, :auth_unsupported.t(:name => name)
      end
    end

    class<< self
      def service
        @service ||= Service.find(Config.authentication.service).new(Config.authentication[Config.authentication.service])
      end

      def validate_password(password, confirm)
        check do |errors|
          errors << :passwords_do_not_match.t if password != confirm
          errors << :empty_password.t if password.blank?
        end
      end

      def anonymous(request)
        ip = request.ip || 'unknown-ip'
        name = request.remote_host ? "#{request.remote_host} (#{ip})" : ip
        new(name, "anonymous@#{ip}", %w(anonymous))
      end

      def find!(name)
        service.find(name)
      end

      def find(name)
        find!(name) rescue nil
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

# -*- coding: utf-8 -*-
module Olelo
  class Config
    include Enumerable

    attr_reader :base, :hash
    alias to_hash hash
    undef_method :type rescue nil if RUBY_VERSION < '1.9'

    def initialize(hash = nil, base = nil)
      @hash = {}
      @base = base
      update(hash) if hash
    end

    def[](key)
      key = key.to_s
      i = key.index('.')
      if i
        not_found(key) if !hash.include?(key[0...i])
        hash[key[0...i]][key[i+1..-1]]
      else
        not_found(key) if !hash.include?(key)
        hash[key]
      end
    end

    def []=(key, value)
      key = key.to_s
      i = key.index('.')
      if i
        child(key[0...i])[key[i+1..-1]] = value
      elsif Hash === value
        child(key).update(value)
      else
        create_accessor(key)
        hash[key] = value
      end
    end

    def update(hash)
      hash.each_pair do |key, value|
        self[key] = value
      end
    end

    def method_missing(key, *args)
      not_found(key)
    end

    def load(file)
      load!(file) if File.file?(file)
    end

    def load!(file)
      update(YAML.load_file(file))
    end

    def each(&block)
      hash.each(&block)
    end

    def self.instance
      @instance ||= Config.new
    end

    def self.method_missing(key, *args)
      instance.send(key, *args)
    end

    private

    def not_found(key)
      raise(NameError, "Configuration key #{path(key)} not found")
    end

    def path(key)
      base ? "#{base}.#{key}" : key
    end

    def child(key)
      create_accessor(key)
      hash[key] ||= Config.new(nil, path(key))
    end

    def create_accessor(key)
      if !respond_to?(key)
        metaclass.class_eval do
          define_method("#{key}?") { !!hash[key] }
          define_method(key) { hash[key] }
          define_method("#{key}=") { |x| hash[key] = x }
        end
      end
    end

  end
end

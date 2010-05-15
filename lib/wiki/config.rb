# -*- coding: utf-8 -*-
module Wiki
  class Config
    include Enumerable

    attr_reader :base, :hash
    alias to_hash hash

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

    def set(key, value)
      key = key.to_s
      i = key.index('.')
      if i
        child(key[0...i]).set(key[i+1..-1], value)
      else
        if Hash === value
          child(key).update(value)
        else
          create_accessor(key)
          hash[key] = value
        end
      end
    end

    def update(hash)
      hash.each_pair do |key, value|
        set(key, value)
      end
    end

    def method_missing(key, *args)
      not_found(key)
    end

    def load(file)
      load!(file) rescue false
    end

    def load!(file)
      update(YAML.load_file(file))
    end

    def each(&block)
      hash.each(&block)
    end

    def self.method_missing(key, *args)
      (@instance ||= Config.new).send(key, *args)
    end

    private

    def not_found(key)
      raise(NameError, "Configuration key #{path(key)} not found")
    end

    def path(key)
      base ? "#{base}.#{key}" : key
    end

    def set_value(key, value)
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

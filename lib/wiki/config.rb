require 'wiki/extensions'

module Wiki
  class Config
    def initialize(hash = nil)
      @config = {}
      update(hash) if hash
    end

    def set(name, value)
      name = name.to_sym
      if !respond_to?(name)
        metaclass.class_eval do
          define_method(name) { @config[name] }
          define_method("#{name}=") { |x| @config[name] = x }
        end
      end
      @config[name] = value.is_a?(Hash) ? Config.new(value) : value
    end

    def method_missing(mid, *args)
      name = mid.to_s
      if name.ends_with?('=')
        raise(ArgumentError, "wrong number of arguments (#{len} for 1)", caller(1)) if args.length != 1
        raise(TypeError, "can't modify frozen #{self.class}", caller(1)) if frozen?
        name.chop!
        set(name, args[0])
      elsif args.length == 0
        @config[mid] || raise(RuntimeError, "configuration key #{mid} is missing for #{self}")
      else
        raise(NoMethodError, "undefined method #{mid} for #{self}", caller(1))
      end
    end

    def delete(name)
      @config.delete name.to_sym
    end

    def update(hash)
      hash.each_pair {|k,v| set(k, v) }
    end

    def reset
      @config.clear
    end

    def load(file)
      load!(file) if File.file?(file)
    end

    def load!(file)
      update(YAML.load_file(file))
    end

    def self.method_missing(name, *args)
      @instance ||= Config.new
      @instance.__send__(name, *args)
    end
  end
end

require 'wiki/extensions'

module Wiki
  module Aspect
    def before_method(name, before_name = nil, &block)
      old = instance_method(name)
      new = block ? lambda(&block).to_method(self) : instance_method(before_name)
      remove_method name
      define_method(name) do |*args|
        args = new.bind(self)[*args]
        args = [args] if !args.is_a? Array
        old.bind(self)[*args]
      end
    end

    def after_method(name, after_name = nil, &block)
      old = instance_method(name)
      new = block ? lambda(&block).to_method(self) : instance_method(after_name)
      remove_method name
      define_method(name) do |*args|
        args = old.bind(self)[*args]
        args = [args] if !args.is_a? Array
        new.bind(self)[*args]
      end
    end

    def around_method(name, around_name = nil, &block)
      old = instance_method(name)
      new = block ? lambda(&block).to_method(self) : instance_method(around_name)
      remove_method name
      define_method(name) { |*args| new.bind(self).call(old.bind(self), *args) }
    end

    def method_missing(name, *args, &block)
      name = name.to_s
      if (name =~ /^before_(\w+)$/)
        before_method($1, *args, &block)
      elsif (name =~ /^after_(\w+)$/)
        after_method($1,*args, &block)
      elsif (name =~ /^around_(\w+)$/)
        around_method($1, *args, &block)
      else
        super(name, *args, &block)
      end
    end
  end
end

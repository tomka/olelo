module Wiki
  module Filter
    def prepend_method(name, &block)
      old = instance_method(name)
      new = lambda(&block).to_method(self)
      remove_method name
      define_method(name) do |*args|
        args = new.bind(self)[*args]
        args = [args] if !args.is_a? Array
        old.bind(self)[*args]
      end
    end

    def append_method(name, &block)
      old = instance_method(name)
      new = lambda(&block).to_method(self)
      remove_method name
      define_method(name) do |*args|
        args = old.bind(self)[*args]
        args = [args] if !args.is_a? Array
        new.bind(self)[*args]
      end
    end

    def around_method(name, &block)
      old = instance_method(name)
      new = lambda(&block).to_method(self)
      remove_method name
      define_method(name) { |*args| new.bind(self).call(old.bind(self), *args) }
    end

    alias method_missing_without_filter method_missing

    def method_missing(name, *args, &block)
      name = name.to_s
      if (name =~ /^append_(\w+)$/)
        append_method($1, &block)
      elsif (name =~ /^prepend_(\w+)$/)
        prepend_method($1, &block)
      elsif (name =~ /^around_(\w+)$/)
        around_method($1, &block)
      else
        method_missing_without_filter(name, *args, &block)
      end
    end
  end
end

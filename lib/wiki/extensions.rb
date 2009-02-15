class Class
  # Define a static function helper block
  # Methods will be available in both
  def static(&block)
    block.call
    instance_eval(&block)
  end

  def prepend(name, &block)
    old = instance_method(name)
    new = lambda(&block).to_method(self)
    remove_method name
    define_method(name) {|*args| old.bind(self)[*new.bind(self)[*args]] }
  end

  def append(name, &block)
    old = instance_method(name)
    new = lambda(&block).to_method(self)
    remove_method name
    define_method(name) {|*args| new.bind(self)[*old.bind(self)[*args]] }
  end
end

class Proc
  def to_method(klass)
    block, name = self, "to_method_#{self.object_id.to_s(36)}"
    klass.class_eval do
      define_method(name, &block)
      method = instance_method(name)
      remove_method(name)
      method
    end
  end
end

class Object
  def metaclass
    class << self; self; end
  end

  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class Symbol
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end

class String
  def pluralize(count, plural)
    "#{count || 0} " + (count.to_s == '1' ? self : plural)
  end

  def last_lines(max)
    lines = split("\n")
    if lines.length <= max
      self
    else
      lines[-max..-1].join("\n")
    end
  end

  def begins_with?(s)
    index(s) == 0
  end

  def ends_with?(s)
    rindex(s) == size - s.size
  end

  def cleanpath
    names = split('/').reject(&:blank?)
    # /root maps to /
    names.delete_at(0) if names[0] == 'root'
    i = 0
    while i < names.length
      case names[i]
      when '..'
        names.delete_at(i)
        if i>0
          names.delete_at(i-1)
          i-=1
        end
      when '.'
        names.delete_at(i)
      else
        i+=1
      end
    end
    names.join('/')
  end

  def urlpath
    path = cleanpath
    path.blank? ? '/root' : '/' + path
  end

  def truncate(max, omission = '...')
    (length > max ? self[0...max] + omission : self)
  end

  def /(name)
    (self + '/' + name).cleanpath
  end
end

class Module
  # Define a static function helper block
  # Methods will be available in both
  # contexts.
  # Methods which are declared in a static
  # block work like C++/Java static methods hence
  # the name :D
  def static(&block)
    block.call
    instance_eval(&block)
  end

  # Generate accessor method with question mark
  def question_accessor(*names)
    names.each do |a|
      module_eval %{ def #{a}?; !!@#{a}; end }
    end
  end
end

class Hash
  # Map hash to hash. Block should return a list with two elements
  def map_to_hash(&block)
    Hash[*(map {|key,value| block[key,value] }.flatten)]
  end
end

class Object
  def metaclass
    (class << self; self; end)
  end

  # Nice blank? helper from rails activesupport
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  # instance_exec implementation for ruby1.8
  if !new.respond_to?(:instance_exec)
    def instance_exec(*args, &block)
      name = "__instance_exec_#{Thread.current.object_id.abs.to_s(36)}"
      metaclass.class_eval { define_method(name, &block) }
      begin
        ret = send(name, *args)
      ensure
        metaclass.class_eval { remove_method(name) } rescue nil
      end
      ret
    end
  end
end

class Symbol
  # Another nice helper from rails activesupport to
  # convert symbols to procs
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end

class String
  # Pluralize string
  def pluralize(count, plural)
    "#{count.to_i} " + (count.to_s == '1' ? self : plural)
  end

  # Return the last n lines of the string
  def last_lines(n)
    lines = split("\n")
    if lines.length <= n
      self
    else
      lines[-n..-1].join("\n")
    end
  end

  # Check if string begins with s
  def begins_with?(s)
    index(s) == 0
  end

  # Check if string ends with s
  def ends_with?(s)
    rindex(s) == size - s.size
  end

  # Clean up path
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

  # Convert string to url path
  def urlpath
    path = cleanpath
    path.blank? ? '/root' : '/' + path
  end

  # Truncate string and add omission
  def truncate(max, omission = '...')
    (length > max ? self[0...max] + omission : self)
  end

  # Concatenate path components
  def /(name)
    (self + '/' + name).cleanpath
  end
end

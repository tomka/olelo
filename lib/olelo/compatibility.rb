class Object
  unless Object.new.respond_to? :tap
    def tap
      yield self
      self
    end
  end
end

class Symbol
  unless :test.respond_to? :upcase
    def upcase
      to_s.upcase.to_sym
    end
  end

  unless :test.respond_to? :downcase
    def downcase
      to_s.downcase.to_sym
    end
  end

  unless :test.respond_to? :capitalize
    def capitalize
      to_s.capitalize.to_sym
    end
  end
end

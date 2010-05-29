class Object
  if !Object.respond_to? :tap
    def tap
      yield self
      self
    end
  end
end

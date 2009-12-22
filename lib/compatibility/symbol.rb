class Symbol
  def upcase
    to_s.upcase.to_sym
  end

  def downcase
    to_s.downcase.to_sym
  end

  def capitalize
    to_s.capitalize.to_sym
  end
end

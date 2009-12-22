class String
  def force_encoding(enc); self; end
  def valid_encoding?; true; end
  def encoding; __ENCODING__; end

  alias encode dup
  alias encode! force_encoding
end

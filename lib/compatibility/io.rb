class IO
  def internal_encoding
    @internal_encoding || Encoding.default_internal
  end

  def external_encoding
    @external_encoding || Encoding.default_external
  end

  def external_encoding=(enc)
    if enc
      @internal_encoding = (Encoding === enc ? enc : Encoding.new(enc))
    else
      @internal_encoding = nil
    end
  end

  def internal_encoding=(enc)
    if enc
      @internal_encoding = (Encoding === enc ? enc : Encoding.new(enc))
    else
      @internal_encoding = nil
    end
  end
end

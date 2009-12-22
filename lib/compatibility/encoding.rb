class Encoding
  def self.const_missing(name)
    enc = Encoding.new(name.to_s)
    const_set(name, enc)
    enc
  end

  attr_reader :name

  def names
    [name]
  end

  def dummy?
    true
  end

  def initialize(name)
    raise ArgumentError if !(String === name)
    @name = name.to_s.upcase.gsub('_', '-')
  end

  def inspect
    "#<Encoding:#{name}>"
  end

  def to_s
    name
  end

  @default_internal = nil
  @default_external = Encoding::UTF_8

  class << self
    ALIASES = {'BINARY'=>'ASCII-8BIT', 'ASCII'=>'US-ASCII'}
    LIST =  [Encoding::UTF_8, Encoding::ASCII_8BIT, Encoding::US_ASCII]

    attr_reader :default_internal, :default_external
    alias find new

    def list
      LIST
    end

    def locale_charmap
      'UTF-8'
    end

    def name_list
      LIST.map(&:name)
    end

    def aliases
      ALIASES
    end

    def compatible?(a, b)
      true
    end

    def default_external=(enc)
      @default_external = (Encoding === enc ? enc : Encoding.new(enc))
    end

    def default_internal=(enc)
      if enc
        @default_internal = (Encoding === enc ? enc : Encoding.new(enc))
      else
        @default_internal = nil
      end
    end
  end

end

def __ENCODING__
  Encoding.default_external
end


description  'Support for XML tag soup in wiki text'
dependencies 'engine/filter'

class TagSoupParser
  include Util

  NAME            = /[:\-\w]+/
  QUOTED_VALUE    = /"[^"]*"|'[^']*'/
  UNQUOTED_VALUE  = /(?:[^\s'"\/>]|\/+[^'"\/>])+/
  QUOTED_ATTR     = /(#{NAME})=(#{QUOTED_VALUE})/
  UNQUOTED_ATTR   = /(#{NAME})=(#{UNQUOTED_VALUE})/
  BOOL_ATTR       = /(#{NAME})/
  ATTRIBUTE       = /\A\s*(#{QUOTED_ATTR}|#{UNQUOTED_ATTR}|#{BOOL_ATTR})/

  def initialize(tags, content)
    @content = content
    @tags = tags
    @output = ''
    @parsed = nil
  end

  def parse(&block)
    @callback = block

    while @content =~ /<(#{NAME})/
      @output << $`
      @content = $'
      name = $1.downcase
      if @tags.include?(name)
        @name = name
        @parsed = $&
        parse_tag
      else
        # unknown tag, continue parsing after it
        @output << $&
      end
    end
    @output << @content
  end

  private

  def parse_attributes
    # Allowed attribute formats
    #   name="value"
    #   name='value'
    #   name=value (no space, ' or " allowed in value)
    #   name (for boolean values)
    @attrs = Hash.with_indifferent_access
    while @content =~ ATTRIBUTE
      @content = $'
      @parsed << $&
      match = $&
      case match
      when QUOTED_ATTR
        @attrs[$1] = unescape_html($2[1...-1])
      when UNQUOTED_ATTR
        @attrs[$1] = unescape_html($2)
      when BOOL_ATTR
        @attrs[$1] = $1
      end
    end
  end

  def parse_tag
    parse_attributes

    case @content
    when /\A\s*\/>/
      # empty tag
      @content = $'
      @parsed << $&
      @output << @callback.call(@name, @attrs, '')
    when /\A\s*>/
      @content = $'
      @parsed << $&
      @output << @callback.call(@name, @attrs, get_inner_text)
    else
      # Tag which begins with <name but has no >.
      # Ignore this and continue parsing after it.
      @output << @parsed
    end
  end

  def get_inner_text
    stack = [@name]
    text = ''
    while !stack.empty?
      case @content
      # Tag begins
      when /\A<(#{NAME})/
        @content = $'
        text << $&
        stack << $1
      # Tag ends
      when /\A<\/(#{NAME})>/
        @content = $'
        if i = stack.rindex($1.downcase)
          stack = stack[0...i]
          text << $& if !stack.empty?
        else
          text << $&
        end
      # Text till the next tag beginning
      when /\A[^<]+/
        text << $&
        @content = $'
      # Suprious <
      when /\A</
        text << '<'
        @content = $'
      end
    end
    text
  end
end

class Olelo::Tag < Filter
  @@tags = {}

  def self.tags
    @@tags
  end

  def self.define(tag, opts = {}, &block)
    name = "TAG #{tag}"
    define_method(name, &block)
    @@tags[tag.to_s] = TagInfo.new(opts.merge(:method => name,
                                              :plugin => Plugin.current(1),
                                              :requires => [opts[:requires] || []].flatten))
  end

  def nested_tags(context, content)
    context.private[:tag_level] ||= 0
    context.private[:tag_level] += 1
    return 'Maximum tag nesting exceeded' if context.private[:tag_level] > MAX_RECURSION
    result = TagSoupParser.new(@@tags, content).parse do |name, attrs, text|
      process_tag(name, attrs, text, context)
    end
    context.private[:tag_level] -= 1
    result
  end

  def subfilter(context, content)
    super(context, nested_tags(context, content))
  end

  def filter(context, content)
    @protected_elements = []
    @protection_prefix = "TAG_#{object_id}_"
    replace_protected_elements(subfilter(context, content))
  end

  private

  MAX_RECURSION = 100
  BLOCK_ELEMENTS = %w(style script address blockquote div h1 h2 h3 h4 h5 h6 ul p ol pre table hr br)
  BLOCK_ELEMENT_REGEX = /<(#{BLOCK_ELEMENTS.join('|')})/

  class TagInfo
    attr_accessor :limit, :requires, :immediate, :method, :description, :plugin
    def initialize(opts)
      opts.each_pair {|k,v| send("#{k}=", v) }
    end
  end

  def process_tag(name, attrs, content, context)
    tag = @@tags[name]

    tag_counter = context.private[:tag_counter] ||= {}
    tag_counter[name] ||= 0
    tag_counter[name] += 1

    if tag.limit && tag_counter[name] > tag.limit
      "#{name}: Tag limit exceeded"
    elsif attr = tag.requires.find {|a| !attrs.include?(a) }
      %{#{name}: Attribute "#{attr}" is required}
    else
      content =
        begin
          send(tag.method, context, attrs, content).to_s
        rescue Exception => ex
          Plugin.current.logger.error ex
          "#{name}: #{escape_html ex.message}"
        end
      if tag.immediate
        content
      else
        @protected_elements << content
        "#{@protection_prefix}#{@protected_elements.length-1}"
      end
    end
  end

  def replace_protected_elements(content)
    # Protected elements can be nested into each other
    MAX_RECURSION.times do
      break if !content.gsub!(/#{@protection_prefix}(\d+)/) do
        element = @protected_elements[$1.to_i]

        # Remove unwanted <p>-tags around block-level-elements
        prefix = $`
        if element =~ BLOCK_ELEMENT_REGEX
          count = prefix.scan('<p>').size - prefix.scan('</p>').size
          count > 0 ? '</p>' + element + '<p>' : element
        else
          element
        end
      end
      content.gsub!(%r{<p>\s*</p>}, '')
    end
    content
  end
end

Filter.register :tag, Tag

Tag.define :nowiki, :description => 'Disable tag and wikitext filtering' do |context, attrs, content|
  escape_html(content)
end

Tag.define :notags, :description => 'Disable tag processing', :immediate => true do |context, attrs, content|
  content
end

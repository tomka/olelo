author       'Daniel Mendler'
description  'Support for XML tag soup in wiki text'
dependencies 'engine/filter'

class Wiki::Tag < Filter
  class << self
    lazy_reader :tags, {}

    def define(tag, opts = {}, &block)
      tags[tag.to_s] = TagInfo.new(block.to_method(self), opts)
    end
  end

  def add_protected_element(content)
    @protected_elements << content
    "#{@protection_prefix}#{@protected_elements.length-1}"
  end

  def nested_tags(context, content)
    context.private[:tag_level] ||= 0
    context.private[:tag_level] += 1
    return 'Maximum tag nesting exceeded' if context.private[:tag_level] > MAX_RECURSION
    Parser.new(self, context, content).parse
  end

  def filter(content)
    @protected_elements = []
    @protection_prefix = "TAG_#{unique_id}_"
    replace_protected_elements(subfilter(nested_tags(context, content)))
  end

  private

  MAX_RECURSION = 100
  MAX_NESTING = 10

  class TagInfo < Struct.new(:limit, :requires, :immediate, :method)
    def initialize(method, opts)
      update(opts.merge(:method => method, :requires => [opts[:requires] || []].flatten))
    end
  end

  def replace_protected_elements(content)
    MAX_NESTING.times do
      break if !content.gsub!(/#{@protection_prefix}(\d+)/) do
        element = @protected_elements[$1.to_i]
        if block_element?(element)
          prefix = $`
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

  def block_element?(element)
    element =~ /<(div|p|ul|ol|table)/
  end

  class Parser
    def initialize(filter, context, content)
      @filter = filter
      @context = context
      @content = content
      @output = ''
      @parsed = nil
    end

    def parse
      while @content =~ /<([:\-\w]+)/
        @output << $`
        @content = $'
        name = $1.downcase
        if Wiki::Tag.tags[name]
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

    def parse_tag
      # Allowed argument formats
      #   name="value"
      #   name='value'
      #   name=value (no space, ' or " allowed in value)
      if @content =~ /\A(\s*([:\-\w]+)=("[^"]+"|'[^']+'|([^\s'"\/>]|\/[^'"\/>])+))+/
        @content = $'
        @parsed << $&
        attrs = $&
        attrs = (attrs.scan(/([:\-\w]+)=("[^"]+"|'[^']+')/).map {|a,b| [a, b[1...-1]] } +
          attrs.scan(/([:\-\w]+)=((?:[^\s'"\/>]|\/[^'"\/>])+)/)).flatten.map {|x| Wiki.html_unescape(x) }
        @attrs = Hash[*attrs].with_indifferent_access
      else
        @attrs = {}
      end

      case @content
      when /\A\s*\/>/
        # empty tag
        @content = $'
        @parsed << $&
        process_tag('')
      when /\A\s*>/
        @content = $'
        @parsed << $&
        process_tag(get_inner_text)
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
        when /\A<([:\-\w]+)/
          @content = $'
          text << $` << $&
          stack << $1
        when /\A<\/([:\-\w]+)>/
          @content = $'
          text << $`
          if i = stack.rindex($1.downcase)
            stack = stack[0...i]
            text << $& if !stack.empty?
          else
            text << $&
          end
        else
          i = @content.index('<')
          if i == 0
            text << '<'
            @content = @content[1..-1]
          elsif i
            text << @content[0...i]
            @content = @content[i..-1]
          else
            text << @content
            break
          end
        end
      end
      text
    end

    def process_tag(text)
      tag = Wiki::Tag.tags[@name]

      tag_counter = @context.private[:tag_counter] ||= {}
      tag_counter[@name] ||= 0
      tag_counter[@name] += 1

      if tag.limit && tag_counter[@name] > tag.limit
        @output << "#{@name}: Tag limit exceeded"
      elsif attr = tag.requires.find {|a| !@attrs.include?(a) }
        @output << %{#{@name}: Attribute "#{attr}" is required}
      else
        text = begin
                 tag.method.bind(@filter).call(@context, @attrs, text).to_s
               rescue Exception => ex
                 @context.logger.error ex
                 "#{@name}: #{Wiki.html_escape ex.message}"
               end
        @output << (tag.immediate ? text : @filter.add_protected_element(text))
      end
    end
  end
end

Filter.register Tag.new(:tag)

Tag.define :nowiki do |context, attrs, content|
  Wiki.html_escape(content)
end

Wiki::Plugin.define 'filter/tag' do
  depends_on 'engine/filter'

  class Wiki::Tag < Wiki::Filter
    include Wiki::Utils

    def self.tags
      @tags.to_a
    end

    def self.define(tag, opts = {}, &block)
      @tags ||= []
      @tags << [tag, opts, block.to_method(self)]
    end

    def filter(content)
      return 'Maximum tag nesting exceeded' if context.level > 3

      matches = []
      self.class.tags.each do |tag|
        name = tag[0]
        content.scan(%r{(<#{name}([^>]*?)(/>|>(.*)</#{name}>))}m) do |match, attrs, _, text|
          matches << [match, attributes(attrs), text || ''] + tag
        end
      end
      matches.sort! { |a,b| b[0].length <=> a[0].length }

      elements = []
      matches.each do |match, attrs, text, tag, opts, method|
        content.sub!(match) do
          if opts[:requires] && attr = [opts[:requires]].flatten.find {|a| attrs[a.to_s].blank? }
            "<span class=\"error\">Attribute \"#{attr}\" is required for tag \"#{tag}\"</span>"
          else
            elements << [method, attrs, text]
            "WIKI_TAG_#{elements.size}"
          end
        end
      end

      content = subfilter(content)

      content.gsub!(/WIKI_TAG_(\d+)/) do |match|
        elem = elements[$1.to_i-1]
        if elem
          method, attr, text = elem
          method.bind(self).call(context, attr, text)
        end
      end
      content
    end

    def attributes(attrs)
      Hash[*attrs.scan(/\s*([^=]+)=("[^"]+"|'[^']+')\s*/).map {|a,b| [a, b[1...-1]] }.flatten]
    end
  end

  Wiki::Filter.register Wiki::Tag.new(:tag)

  Wiki::Tag.define :nowiki do |context, attrs, content|
    escape_html(content)
  end
end

Wiki::Plugin.define 'filter/tag' do
  depends_on 'engine/filter'
  require 'hpricot'

  class Wiki::Tag < Wiki::Filter
    include Wiki::Utils

    def self.tags
      @tags || {}
    end

    def self.define(tag, opts = {}, &block)
      @tags ||= {}
      @tags[tag.to_s] = [opts, block.to_method(self)]
    end

    def filter(content)
      return 'Maximum tag nesting exceeded' if context.level > 3

      doc = Hpricot.XML(content)

      elements = []
      doc.each_child do |elem|
        if elem.elem?
          tag = self.class.tags[elem.stag.name]
          if tag
            opts, method = tag
            attrs = elem.attributes
            text = elem.children.map { |x| x.to_original_html }.join
            if opts[:requires] && attr = [opts[:requires]].flatten.find {|a| attrs[a.to_s].blank? }
              elem.swap "<span class=\"error\">Attribute \"#{attr}\" is required for tag \"#{tag}\"</span>"
            else
              elements << [method, attrs, text]
              elem.swap "WIKI_TAG_#{elements.length-1}"
            end
          end
        end
      end

      content = subfilter(doc.to_original_html)

      content.gsub!(/WIKI_TAG_(\d+)/) do |match|
        elem = elements[$1.to_i]
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

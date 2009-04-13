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

    def nested_tags(context, content)
      return 'Maximum tag nesting exceeded' if context.level > 3
      doc = Hpricot.XML(content)
      @elements ||= []
      walk_elements(doc, context)
      doc.to_original_html
    end

    def filter(content)
      content = subfilter(nested_tags(context, content))
      content.gsub!(/WIKI_TAG_(\d+)/) { |match| @elements[$1.to_i] }
      content
    end

    private

    def walk_elements(parent, context)
      parent.each_child do |elem|
        if elem.elem?
          name = elem.stag.name.downcase
          tag = self.class.tags[name]
          if tag
            opts, method = tag
            attrs = elem.attributes
            text = elem.children.map { |x| x.to_original_html }.join
            if opts[:requires] && attr = [opts[:requires]].flatten.find {|a| attrs[a.to_s].blank? }
              elem.swap "#{name}: Attribute \"#{attr}\" is required"
            else
              text = begin
                       method.bind(self).call(context, attrs, text)
                     rescue Exception => ex
                       "#{name}: #{ex.message}"
                     end
              if opts[:immediate]
                elem.swap text
              else
                @elements << text
                elem.swap "WIKI_TAG_#{@elements.length-1}"
              end
            end
          else
            walk_elements(elem, context)
          end
        end
      end
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

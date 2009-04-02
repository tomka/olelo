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

    def before(content)
      @elements = []
      self.class.tags.each do |tag|
        content.gsub!(%r{<#{tag[0]}([^>]*)>(.*?)</#{tag[0]}>}m) do |match|
          @elements << [tag, attributes($1), $2]
          "WIKI_TAG_#{@elements.size}"
        end
        content.gsub!(%r{<#{tag[0]}([^>]*)/>}m) do |match|
          @elements << [tag, attributes($1), '']
          "WIKI_TAG_#{@elements.size}"
        end
      end
      content
    end

    def after(content)
      content.gsub!(/WIKI_TAG_(\d+)/) do |match|
        elem = @elements[$1.to_i-1]
        if elem
          tag, attrs, text = elem
          opts = tag[1]
          method = tag[2]
          tag = tag[0]

          if opts[:requires] && attr = [opts[:requires]].flatten.find {|a| attrs[a.to_s].blank? }
            "<span class=\"error\">Attribute \"#{attr}\" is required for tag \"#{tag}\"</span>"
          else
            method.bind(self).call(page, attrs, text)
          end
        else
          ''
        end
      end
      content
    end

    def attributes(attrs)
      Hash[*attrs.split(/\s+/).map {|x| x =~ /^([^=]+)=("[^"]+"|'[^']+')$/ ? [$1, $2[1...-1]] : nil }.compact.flatten]
    end
  end

  Wiki::Filter.register Wiki::Tag.new('tag')

  Wiki::Tag.define :nowiki do |page, attrs, content|
    escape_html(content)
  end
end

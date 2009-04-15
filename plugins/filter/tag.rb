Wiki::Plugin.define 'filter/tag' do
  depends_on 'engine/filter'
  require 'hpricot'

  class Wiki::Tag < Wiki::Filter
    include Wiki::Utils

    MAXIMUM_RECURSION = 100

    def self.tags
      @tags || {}
    end

    def self.define(tag, opts = {}, &block)
      @tags ||= {}
      @tags[tag.to_s] = [opts, block]
    end

    def nested_tags(context, content)
      context['TAG_RECURSION'] += 1
      return 'Maximum tag nesting exceeded' if context['TAG_RECURSION'] > MAXIMUM_RECURSION
      doc = Hpricot.XML(content)
      walk_elements(context, doc)
      doc.to_original_html
    end

    def filter(content)
      @elements = []
      @tag_counter = {}
      context['TAG_RECURSION'] = 0
      content = subfilter(nested_tags(context, content))
      content.gsub!(/TAG_(\d+)/) { |match| @elements[$1.to_i] }
      content
    end

    private

    def walk_elements(context, parent)
      parent.each_child do |elem|
        if elem.elem?
          name = elem.name.downcase
          tag = self.class.tags[name]
          if tag
            @tag_counter[name] ||= 0
            @tag_counter[name] += 1
            opts, block = tag
            if opts[:limit] && @tag_counter[name] > opts[:limit]
              elem.swap "#{name}: Tag limit exceeded"
            elsif opts[:requires] && attr = [opts[:requires]].flatten.find {|a| elem[a.to_s].blank? }
              elem.swap "#{name}: Attribute \"#{attr}\" is required"
            else
              text = elem.children ? elem.children.map { |x| x.to_original_html }.join : ''
              text = begin
                       instance_exec(context, elem.attributes, text, &block)
                     rescue Exception => ex
                       "#{name}: #{ex.message}"
                     end
              if opts[:immediate]
                if text.blank?
                  parent.children.delete(elem)
                else
                  elem.swap text
                end
              else
                @elements << text
                elem.swap "TAG_#{@elements.length-1}"
              end
            end
          else
            walk_elements(context, elem)
          end
        end
      end
    end
  end

  Wiki::Filter.register Wiki::Tag.new(:tag)

  Wiki::Tag.define :nowiki do |context, attrs, content|
    escape_html(content)
  end
end

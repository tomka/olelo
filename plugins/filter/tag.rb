depends_on 'engine/filter'
require 'hpricot'

class Wiki::Engine::Context
  def tag_recursion=(x)
    self['__TAG_RECURSION__'] = x
  end

  def tag_recursion
    self['__TAG_RECURSION__'] || 0
  end

  def tag_counter
    self['__TAG_COUNTER__'] ||= {}
  end
end

class Wiki::Tag < Filter
  MAXIMUM_RECURSION = 100

  def self.tags
    @tags || {}
  end

  def self.define(tag, opts = {}, &block)
    @tags ||= {}
    @tags[tag.to_s] = [opts, block]
  end

  def nested_tags(context, content)
    context.tag_recursion += 1
    return 'Maximum tag nesting exceeded' if context.tag_recursion > MAXIMUM_RECURSION
    doc = Hpricot.XML(content)
    walk_elements(context, doc)
    doc.to_original_html
  end

  def filter(content)
    @elements = []
    @prefix = "TAG_#{Thread.current.object_id.abs.to_s(36)}_"
    content = subfilter(nested_tags(context, content))
    10.times do
      break if !content.gsub!(/#{@prefix}(\d+)/) { |match| @elements[$1.to_i] }
    end
    content
  end

  private

  def walk_elements(context, parent)
    parent.each_child do |elem|
      if elem.elem?
        name = elem.name.downcase
        tag = self.class.tags[name]
        if tag
          context.tag_counter[name] ||= 0
          context.tag_counter[name] += 1
          opts, block = tag
          if opts[:limit] && context.tag_counter[name] > opts[:limit]
            elem.swap "#{name}: Tag limit exceeded"
          elsif opts[:requires] && attr = [opts[:requires]].flatten.find {|a| elem[a.to_s].blank? }
            elem.swap "#{name}: Attribute \"#{attr}\" is required"
          else
            text = elem.children ? elem.children.map { |x| x.to_original_html }.join : ''
            text = begin
                     instance_exec(context, elem.attributes.with_indifferent_access, text, &block)
                   rescue Exception => ex
                     "#{name}: #{escape_html ex.message}"
                   end
            if opts[:immediate]
              if !(String === text) || text.blank?
                parent.children.delete(elem)
              else
                elem.swap text
              end
            else
              @elements << text
              elem.swap "#{@prefix}#{@elements.length-1}"
            end
          end
        else
          walk_elements(context, elem)
        end
      end
    end
  end
end

Filter.register Tag.new(:tag)

Tag.define :nowiki do |context, attrs, content|
  escape_html(content)
end

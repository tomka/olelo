require 'hpricot'
require 'wiki/filter'

module Wiki
  class Engine
    module Tags
      def self.included(base)
        return if base.respond_to? :define_tag
        base.extend(ClassMethods)
        base.class_eval do
          include InstanceMethods
          around_filter :handle_tags
        end
      end

      module InstanceMethods
        def handle_tags(engine, page, content)
          doc = Hpricot(content)
          elements = []
          metaclass.tags.each do |tag|
            name, method = tag
            (doc/name).each do |elem|
              elements << [method, elem.inner_text, elem.attributes]
              elem.swap "WIKI_TAG_#{elements.length-1}"
            end
          end
          content = doc.to_html
          page, content = engine[page, content]
          content.gsub!(/WIKI_TAG_(\d+)/) do |match|
            elem = elements[$1.to_i]
            if elem
              elem[0].bind(self).call(page, elem[1], elem[2])
            else
              match
            end
          end
          [page, content]
        end
      end

      module ClassMethods
        attr_reader :tags

        def define_tag(tag, &block)
          @tags ||= []
          @tags << [tag, proc(&block).to_method(self)]
        end
      end

    end
  end
end

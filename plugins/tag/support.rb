Wiki::Plugin.define 'tag/support' do
  require 'hpricot'

  module TagSupport
    def self.included(base)
      return if base.respond_to? :define_tag
      base.extend(ClassMethods)
      base.class_eval { include InstanceMethods }
    end

    module InstanceMethods
      def handle_tags(engine, page, content)
        doc = Hpricot::XML(content)
        elements = []
        self.class.tags.each do |tag|
          name, method = tag
          (doc/name).each do |elem|
            elements << [method, elem]
            elem.swap "WIKI_TAG_#{elements.length-1}"
          end
        end
        content = doc.to_html
        page, content = engine[page, content]
        content.gsub!(/WIKI_TAG_(\d+)/) do |match|
          elem = elements[$1.to_i]
          if elem
            elem[0].bind(self).call(page, elem[1])
          else
            match
          end
        end
        [page, content]
      end
    end

    module ClassMethods
      def tag_handler
        instance_methods.select {|x| x.begins_with? 'TAG ' }.map {|x| [x[4..-1], instance_method(x)] }
      end

      def define_tag(tag, opts = {}, &block)
        around_filter :handle_tags if tag_handler.empty?
        method = block.to_method(self)
        define_method("TAG #{tag}") do |page, elem|
          if opts[:requires] && attr = [opts[:requires]].flatten.find {|a| elem.attributes[a.to_s].blank? }
            "<span class=\"error\">Attribute \"#{attr}\" is required for tag \"#{tag}\"</span>" if elem.attributes[attr.to_s].blank?
          else
            method.bind(self)[page, elem]
          end
        end
      end
    end
  end

  class Wiki::Engine
    include TagSupport
  end
end

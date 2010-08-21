# -*- coding: utf-8 -*-
module Olelo
  module AttributeEditor
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def attributes
        @attributes ||= {}
      end

      def register_attribute(name, type = nil, &block)
        attributes[name.to_s] = block ? block : type
      end
    end

    def update_attributes(attributes)
      self.class.attributes.map do |key, type|
        value = params["attribute_#{key}"]
        attributes.delete(key)
        type = type.call if type.respond_to? :call
        case type
        when :integer
          attributes[key] = value.to_i if !value.blank?
        when :boolean
          attributes[key] = true if value == 'true'
        when :string
          attributes[key] = value if !value.blank?
        when :stringlist
          attributes[key] = value.split(/\s*,\s*/) if !value.blank?
        when Array, Hash
          attributes[key] = value if type.include?(value)
        else
          raise "Invalid attribute type #{type}"
        end
      end
    end

    def attribute_editor(attributes)
      self.class.attributes.map do |key, type|
        label = escape_html I18n.translate("attribute_#{key}", :fallback => key.tr('_', ' ').capitalize)
        html = %{<label for="attribute_#{key}">#{label}</label>}
        type = type.call if type.respond_to? :call
        case type
        when :integer, :string
          html << %{<input type="text" id="attribute_#{key}" name="attribute_#{key}" value="#{escape_html attributes[key]}"/><br/>}
        when :stringlist
          html << %{<input type="text" id="attribute_#{key}" name="attribute_#{key}" value="#{escape_html attributes[key].to_a.join(', ')}"/><br/>}
        when :boolean
          html << %{<input type="checkbox" id="attribute_#{key}" name="attribute_#{key}" value="true"#{attributes[key] ? ' checked="checked"' : ''}/><br/>}
        when Hash
          html << %{<select id="attribute_#{key}" name="attribute_#{key}"><option></option>}
          type.each do |value,label|
            html << %{<option value="#{escape_html value}"#{attributes[key] == value ? ' selected="selected"' : ''}>#{escape_html label}</option>}
          end
          html << '</select><br/>'
        when Array
          html << %{<select id="attribute_#{key}" name="attribute_#{key}"><option></option>}
          type.each do |value|
            html << %{<option#{attributes[key] == value ? ' selected="selected"' : ''}>#{escape_html value}</option>}
          end
          html << '</select><br/>'
        else
          raise "Invalid attribute type #{type}"
        end
        [label, html]
      end.sort_by(&:first).map(&:last).join
    end
  end
end

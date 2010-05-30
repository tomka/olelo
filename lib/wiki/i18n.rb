# -*- coding: utf-8 -*-
module Wiki
  module I18n
    @locale = Hash.with_indifferent_access
    @loaded = []

    class << self
      def load(path)
        if !@loaded.include?(path) && File.file?(path)
          locale = YAML.load_file(path)
          @locale.update(locale[$1] || {}) if Config.locale =~ /^(\w+)(_|-)/
          @locale.update(locale[Config.locale] || {})
          @loaded << path
        end
      end

      def translate(key, args = {})
        args = args.with_indifferent_access
        if !key.to_s.ends_with?('_plural') && args[:count] && args[:count] != 1
          translate("#{key}_plural", args)
        elsif @locale[key]
          @locale[key].gsub(/#\{(\w+)\}/) {|x| args.include?($1) ? args[$1].to_s : x }
        else
          "##{key}"
        end
      end
    end
  end
end

class Symbol
  def t(args = {})
    Wiki::I18n.translate(self, args)
  end
end

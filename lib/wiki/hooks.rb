# -*- coding: utf-8 -*-
require 'wiki/extensions'

module Wiki
  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    class Result < Array
      def to_s
        map(&:to_s).join
      end
    end

    def with_hooks(type, *args)
      result = Result.new
      result.push(*invoke_hook(:"before_#{type}", *args))
      result << yield
    ensure
      result.push(*invoke_hook(:"after_#{type}", *args))
    end

    def invoke_hook(type, *args)
      self.class.invoke_hook(self, type, *args)
    end

    module ClassMethods
      lazy_reader :hooks, {}

      def hook(type, priority = 0, &block)
        (hooks[type] ||= []) << [-priority, block.to_method(self)]
      end

      def invoke_hook(source, type, *args)
        result = Result.new
        while type
          result.push(*hooks[type].to_a.sort_by(&:first).map {|priority, method| method.bind(source).call(*args) })
          break if type == Object
          type = type.superclass rescue nil
        end
        result
      end
    end
  end
end

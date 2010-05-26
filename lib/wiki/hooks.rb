# -*- coding: utf-8 -*-
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
      result.push(*invoke_hook("before #{type}", *args))
      result << yield
    ensure
      result.push(*invoke_hook("after #{type}", *args))
    end

    def invoke_hook(type, *args)
      result = Result.new
      while type
        result.push(*self.class.hooks[type].to_a.sort_by(&:first).map {|priority, method| method.bind(self).call(*args) })
        break if type == Object
        type = Class === type ? type.superclass : nil
      end
      result
    end

    module ClassMethods
      lazy_reader :hooks, {}

      def hook(type, priority = 0, &block)
        (hooks[type] ||= []) << [-priority, block.to_method(self)]
      end

      def before(type, priority = 0, &block)
        hook("before #{type}", priority, &block)
      end

      def after(type, priority = 0, &block)
        hook("after #{type}", priority, &block)
      end
    end
  end
end

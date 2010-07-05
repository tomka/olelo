# -*- coding: utf-8 -*-
module Wiki
  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Invoke before/after hooks
    def with_hooks(type, *args)
      result = []
      result.push(*invoke_hook("before #{type}", *args))
      result << yield
    ensure
      result.push(*invoke_hook("after #{type}", *args))
    end

    # Invoke hooks
    def invoke_hook(type, *args)
      result = []
      while type
        result.push(*self.class.hooks[type].to_a.sort_by(&:first).map {|priority, method| method.bind(self).call(*args) })
        break if type == Object
        type = Class === type ? type.superclass : nil
      end
      result
    end

    module ClassMethods
      def hooks
        @hooks ||= {}
      end

      # Register hook. Hook with lowest priority is executed first.
      def hook(type, priority = 99, &block)
        (hooks[type] ||= []) << [priority, block.to_method(self)]
      end

      # Register before hook
      def before(type, priority = 99, &block)
        hook("before #{type}", priority, &block)
      end

      # Register after hook
      def after(type, priority = 99, &block)
        hook("after #{type}", priority, &block)
      end
    end
  end
end

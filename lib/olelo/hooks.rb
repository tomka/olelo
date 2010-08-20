# -*- coding: utf-8 -*-
module Olelo
  module Hooks
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Invoke before/after hooks
    def with_hooks(type, *args)
      result = []
      result.push(*invoke_hook("BEFORE #{type}", *args))
      result << yield
    ensure
      result.push(*invoke_hook("AFTER #{type}", *args))
    end

    # Invoke hooks
    def invoke_hook(type, *args)
      result = []
      while type
        result.push(*self.class.hooks[type].to_a.sort_by(&:first).map {|priority, name| send(name, *args) })
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
        hooks[type] ||= []
        name = "HOOK #{type.to_s} #{hooks[type].size}"
        define_method(name, &block)
        hooks[type] << [priority, name]
      end

      # Register before hook
      def before(type, priority = 99, &block)
        hook("BEFORE #{type}", priority, &block)
      end

      # Register after hook
      def after(type, priority = 99, &block)
        hook("AFTER #{type}", priority, &block)
      end
    end
  end
end

# -*- coding: utf-8 -*-
module Olelo
  class Timer
    def initialize
      @elapsed = 0
      @start = nil
    end

    # Create timer and start it
    def self.start
      Timer.new.start
    end

    # Start or restart timer
    def start
      @start = Time.now if !@start
      self
    end

    # Stop timer
    def stop
      if @start
        @elapsed += Time.now - @start
        @start = nil
      end
      self
    end

    # Elapsed seconds
    def elapsed_sec
      raise 'Timer is running' if @start
      @elapsed
    end

    # Elapsed milliseconds
    def elapsed_ms
      (elapsed_sec * 1000).to_i
    end

    def measure
      start
      yield
    ensure
      stop
    end

    def measure_not
      stop
      yield
    ensure
      start
    end
  end
end

require 'wiki/extensions'

module Wiki
  class MultiError < StandardError
    attr_accessor :messages

    def initialize(*messages)
      @messages = messages
    end

    def message
      @messages.join("\n")
    end
  end

  module Utils
    def self.included(base)
      # Also as class methods
      base.extend self
    end

    def escape_html(html)
      CGI::escapeHTML(html.to_s)
    end

    def forbid(conds)
      failed = conds.keys.select {|key| conds[key] }
      raise(MultiError, failed) if !failed.empty?
    end
  end
end

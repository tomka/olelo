require 'wiki/extensions'

module Wiki
  class MessageError < StandardError; end

  module Utils
    def self.included(base)
      base.extend self
    end

    def forbid(conds)
      failed = conds.keys.select {|key| conds[key]}
      raise MessageError.new(failed) if !failed.empty?
    end

    def safe_require(name)
      require(name)
      true
    rescue LoadError
      false
    end

    def safe_require_all(name)
      Dir.glob(File.join(name, '**/*.rb')).each { |file| safe_require file }
    end
  end
end

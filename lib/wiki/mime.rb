require 'wiki/mime_tables'
require 'wiki/extensions'

module Wiki
  class Mime
    attr_reader :type, :mediatype, :subtype

    def initialize(type)
      @type      = type
      @mediatype = @type.split('/')[0]
      @subtype   = @type.split('/')[1]
    end

    def self.add(type, extensions, parents, &block)
      TYPES[type] = [extensions, parents, block_given? ? proc(&block) : nil]
      extensions.each do |ext|
        EXTENSIONS[ext] = type
      end
    end

    def text?
      child_of? 'text/plain'
    end

    def child_of?(parent)
      child?(type, parent)
    end

    def extensions
      TYPES.key?(type) ? TYPES[type][0] : []
    end

    def self.by_extension(ext)
      mime = EXTENSIONS[ext.downcase]
      mime ? new(mime) : nil
    end

    def self.by_magic(content)
      io = content.respond_to?(:rewind) ? content : StringIO.new(content.to_s, 'rb')
      mime = TYPES.keys.find do |type|
        io.rewind
        TYPES[type][2] && TYPES[type][2].call(io)
      end
      mime ? new(mime) : nil
    end

    def to_s
      type
    end

    def ==(x)
      type == x.to_s
    end

    private

    def child?(child, parent)
      return true if child == parent
      TYPES.key?(child) ? TYPES[child][1].any? {|p| child?(p, parent) } : false
    end
  end
end

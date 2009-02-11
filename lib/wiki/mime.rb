require 'wiki/mime_tables'
require 'wiki/extensions'

module Wiki
  class Mime
    attr_reader :type, :mediatype, :subtype

    def self.add(type, extensions, parents)
      TYPES[type] = [extensions, parents]
      extensions.each do |ext|
        EXTENSIONS[ext] = type
      end
    end
    
    def text?
      child_of? 'text/plain'
    end
    
    def child_of?(parent)
      Mime.child?(type, parent)
    end
    
    def extensions
      TYPES.include?(type) ? TYPES[type][0] : []
    end
    
    def self.by_extension(ext)
      mime = EXTENSIONS[ext.downcase]
      mime ? new(mime) : nil
    end
    
    def to_s
      type
    end

    def ==(x)
      type == x.to_s
    end
    
    def initialize(type)
      @type      = type
      @mediatype = @type.split('/')[0]
      @subtype   = @type.split('/')[1]
    end
    
    private

    def self.child?(child, parent)
      return true if child == parent
      TYPES.include?(child) ? TYPES[child][1].any? {|p| child?(p, parent) } : false
    end
  end
end

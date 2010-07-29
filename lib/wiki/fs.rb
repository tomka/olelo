# -*- coding: utf-8 -*-
module Wiki
  class DirectoryFS < Struct.new(:dir)
    def fs_id
      "D<#{dir}>"
    end

    def read(name)
      raise IOError if !dir
      File.read(File.join(dir, name))
    end

    def glob(*names)
      return [] if !dir
      names.map do |name|
        Dir[File.join(dir, name)].select {|f| File.file?(f) }
      end.flatten.each {|f| yield(self, f[dir.length+1..-1]) }
    end

    def open(name)
      raise IOError if !dir
      BlockFile.open(File.join(dir, name), 'rb')
    end

    def mtime(name)
      raise IOError if !dir
      File.mtime(File.join(dir, name))
    end

    def size(name)
      raise IOError if !dir
      File.stat(File.join(dir, name)).size
    end
  end

  class InlineFS < Struct.new(:file)
    def fs_id
      "I<#{file}>"
    end

    def read(name)
      raise IOError if !file
      code, data = File.read(file).split('__END__')
      content = nil
      data.to_s.each_line do |line|
        if line =~ /^@@\s*([^\s]+)\s*/
          if name == $1
            content = ''
          elsif content
            break
          end
        elsif content
          content << line
        end
      end
      content || raise(IOError, "#{name} not found")
    end

    def glob(*names)
      return [] if !file
      code, data = File.read(file).split('__END__')
      data.to_s.each_line do |line|
        yield(self, $1) if line =~ /^@@\s*([^\s]+)\s*/ && names.any? {|pattern| File.fnmatch(pattern, $1) }
      end
    end

    def open(name)
      [read(name)]
    end

    def mtime(name)
      raise IOError if !file
      File.mtime(file)
    end

    def size(name)
      read(name).size
    end
  end

  class CacheInlineFS < InlineFS
    def read(name)
      @cache ||= {}
      @cache[name] ||= super
    end
  end

  class UnionFS
    def initialize(*fs)
      @fs = fs
    end

    def fs_id
      "U<#{@fs.map(&:fs_id).join(' ')}>"
    end

    def glob(*names, &block)
      @fs.each {|fs| fs.glob(*names, &block) }
    end

    def method_missing(method, *args)
      @fs.each do |fs|
        begin
          return fs.send(method, *args)
        rescue
        end
      end
      raise IOError, "#{method}(#{args.map(&:inspect).join(', ')}) failed"
    end
  end
end

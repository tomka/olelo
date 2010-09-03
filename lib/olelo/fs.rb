module Olelo
  class VirtualFile
    attr_reader :fs, :name

    def initialize(fs, name)
      @fs = fs
      @name = name
    end

    def read
      fs.read(name)
    end

    def open
      fs.open(name)
    end

    def mtime
      @mtime ||= fs.mtime(name)
    end

    def size
      @size ||= fs.size(name)
    end

    def mime
      MimeMagic.by_extension(File.extname(name)) || MimeMagic.new('application/octet-stream')
    end
  end

  class DirectoryFS
    def initialize(dir)
      @dir = dir
    end

    def read(name)
      File.read(File.join(@dir, name))
    end

    def glob(*names)
      names.map do |name|
        Dir[File.join(@dir, name)].select {|f| File.file?(f) }
      end.flatten.each do |f|
        yield(VirtualFile.new(self, f[@dir.length+1..-1]))
      end
    end

    def open(name)
      BlockFile.open(File.join(@dir, name), 'rb')
    end

    def mtime(name)
      File.mtime(File.join(@dir, name))
    end

    def size(name)
      File.stat(File.join(@dir, name)).size
    end
  end

  class InlineFS
    def initialize(file)
      @file = file
      @cache = {}
    end

    def read(name)
      @cache[name] ||= begin
        code, data = File.read(@file).split('__END__')
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
    end

    def glob(*names)
      code, data = File.read(@file).split('__END__')
      data.to_s.each_line do |line|
        if line =~ /^@@\s*([^\s]+)\s*/ && names.any? {|pattern| File.fnmatch(pattern, $1) }
          yield(VirtualFile.new(self, $1))
        end
      end
    end

    def open(name)
      [read(name)]
    end

    def mtime(name)
      File.mtime(@file)
    end

    def size(name)
      read(name).bytesize
    end
  end

  class UnionFS
    def initialize(*fs)
      @fs = fs
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

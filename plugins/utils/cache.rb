description  'Cache class'

# Cache base class
class Olelo::Cache
  include Util

  class<< self
    def instance
      @instance ||= Disk.new(File.join(Config.tmp_path, 'cache'))
    end

    def cache(*args, &block)
      instance.cache(*args, &block)
    end
  end

  class Disabler
    attr_reader? :disabled

    def initialize
      @disabled = false
    end

    def disable!
      @disabled = true
    end
  end

  # Block around cacheable return value identified by a <i>key</i>.
  # The following options can be specified:
  # * :disable Disable caching
  # * :update Force cache update
  def cache(key, opts = {}, &block)
    key = md5(key)
    if opts[:disable] || !Config.production?
      yield(Disabler.new)
    elsif exist?(key) && !opts[:update]
      content = read(key)
      opts[:marshal] ? Marshal.restore(content) : content
    else
      disabler = Disabler.new
      content = yield(disabler)
      write(key, opts[:marshal] ? Marshal.dump(content) : content) if !disabler.disabled?
      content
    end
  end

  # File based cache
  class Disk < Cache
    attr_reader :root

    # Cache constructor which specifies a <i>root</i> directory
    def initialize(root)
      @root = root
      FileUtils.mkdir_p root, :mode => 0755
    end

    # Exists the entry with <i>key</i>
    def exist?(key)
      File.exist?(cache_path(key))
    end

    # Read entry with <i>key</i>
    def read(key)
      File.read(cache_path(key))
    rescue Errno::ENOENT
      nil
    end

    # Open file with <i>key</i>.
    # Returns open BlockFile instance.
    def open(key)
      BlockFile.open(cache_path(key), 'rb')
    rescue Errno::ENOENT
      nil
    end

    # Write entry <i>content</i> with <i>key</i>.
    def write(key, content)
      temp_file = File.join(root, ['tmp', $$, Thread.current.unique_id].join('-'))
      File.open(temp_file, 'wb') do |dest|
        if content.respond_to? :to_str
          dest.write(content.to_str)
        else
          content.each {|s| dest.write(s) }
        end
      end

      path = cache_path(key)
      if File.exist?(path)
        File.unlink temp_file
      else
        FileUtils.mkdir_p File.dirname(path), :mode => 0755
        FileUtils.mv temp_file, path
      end
      true
    rescue
      File.unlink temp_file rescue false
      false
    end

    # Remove entry with <i>key</i>
    def remove(key)
      File.unlink cache_path(key)
    rescue Errno::ENOENT
    end

    protected

    def cache_path(key)
      File.join(root, key[0..1], key[2..-1])
    end
  end
end

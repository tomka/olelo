description  'Cache class'
dependencies 'engine/engine'

# Cache base class
class Wiki::Cache
  class<< self
    # Accessor for the default cache instance
    def instance
      @instance ||= Disk.new(File.join(Config.tmp_path, 'cache'))
    end

    # Block around cacheable return value belonging to
    # a <i>bucket<i>, identified by a <i>key</i>. The
    # default cache is used.
    # The following options can be specified:
    # * :disable Disable caching
    # * :update Force cache update
    # * :marshal Marshal object before store
    def cache(key, opts = {}, &block)
      instance.cache(key, opts, &block)
    end
  end

  # Block around cacheable return value identified by a <i>key</i>.
  # The following options can be specified:
  # * :disable Disable caching
  # * :update Force cache update
  # * :marshal Marshal object before store
  def cache(key, opts = {}, &block)
    return yield if opts[:disable] || !Config.production?
    if exist?(key) && !opts[:update]
      content = read(key)
      return opts[:marshal] ? Marshal.restore(content) : content
    end
    content = yield
    write(key, opts[:marshal] ? Marshal.dump(content) : content)
    content
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

# Provide engine with caching
class Wiki::Engine
  redefine_method :cached_output do |context|
    context_id = md5(name + context.resource.path + context.resource.version.to_s + context.params.to_a.sort.inspect)

    content, vars = Cache.cache(context_id,
                :disable => context.resource.modified? || !cacheable?,
                :update => context.request && context.request.no_cache?,
                :marshal => true) do
      [output(context), context.private]
    end
    context.private = vars
    content
  end
end

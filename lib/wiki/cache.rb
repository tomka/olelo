# -*- coding: utf-8 -*-
require 'wiki/utils'
require 'wiki/config'

module Wiki

  # Cache base class
  class Cache
    class<< self
      # Accessor for the default cache instance
      lazy_reader(:instance) { Disk.new(Config.cache) }

      # Block around cacheable return value belonging to
      # a <i>bucket<i>, identified by a <i>key</i>. The
      # default cache is used.
      # The following options can be specified:
      # * :disable Disable caching
      # * :update Force cache update
      def cache(bucket, key, opts = {}, &block)
        instance.cache(bucket, key, opts, &block)
      end
    end

    # Block around cacheable return value belonging to
    # a <i>bucket<i>, identified by a <i>key</i>.
    # The following options can be specified:
    # * :disable Disable caching
    # * :update Force cache update
    def cache(bucket, key, opts = {}, &block)
      return yield if opts[:disable] || !Config.production?
      return read(bucket, key) if exist?(bucket, key) && !opts[:update]
      content = yield
      write(bucket, key, content)
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

      # Exists the entry in the <i>bucket</i> with <i>key</i>
      def exist?(bucket, key)
        File.exist?(cache_path(bucket, key))
      end

      # Read entry in the <i>bucket</i> with <i>key</i>
      def read(bucket, key)
        File.read(cache_path(bucket, key))
      rescue Errno::ENOENT
        nil
      end

      # Open file in the <i>bucket</i> with <i>key</i>.
      # Returns open BlockFile instance.
      def open(bucket, key)
        BlockFile.open(cache_path(bucket, key), 'rb')
      rescue Errno::ENOENT
        nil
      end

      # Write entry <i>content</i> in <i>bucket</i> with <i>key</i>.
      def write(bucket, key, content)
        temp_file = File.join(root, ['tmp', $$, Thread.current.object_id.abs.to_s(36)].join('-'))
        File.open(temp_file, 'wb') do |dest|
          if content.respond_to? :to_str
	    dest.write(content.to_str)
	  else
	    content.each {|s| dest.write(s) }
          end
        end

        path = cache_path(bucket, key)
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

      # Remove entry with <i>key</i> from <i>bucket</i>
      def remove(bucket, key)
        File.unlink cache_path(bucket, key)
      rescue Errno::ENOENT
      end

      protected

      def cache_path(bucket, key)
        File.join(root, bucket, key)
      end
    end

  end
end

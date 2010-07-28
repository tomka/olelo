# -*- coding: utf-8 -*-
module Wiki
  class MultiError < StandardError
    attr_accessor :messages

    def initialize(messages)
      @messages = messages
    end

    def message
      @messages.join(', ')
    end
  end

  module Factory
    def registry
      @registry ||= {}
    end

    def register(name, klass)
      name = name.to_s
      raise(ArgumentError, "Implementation '#{name}' already exists for '#{self.name}'") if registry.key?(name)
      registry[name] = klass
    end

    def[](name)
      registry[name.to_s] || raise(NameError, "Implementation '#{name}' for '#{self.name}' not found")
    end
  end

  class BlockFile < ::File
    alias to_path path

    def each
      rewind
      while part = read(8192)
        yield part
      end
    end
  end

  module Util
    def self.included(base)
      base.extend(Util)
    end

    extend self

    def check
      errors = []
      yield(errors)
      raise MultiError, errors if !errors.empty?
    end

    # Like CGI.escape but escapes space not as +
    def escape(s)
      s.gsub(/([^a-zA-Z0-9_.-]+)/) do
        '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
      end
    end

    # Like CGI.unescape but does not unescape +
    def unescape(s)
      if s.respond_to? :encoding
        enc = s.encoding
        s.gsub(/((?:%[0-9a-fA-F]{2})+)/) do
          [$1.delete('%')].pack('H*').force_encoding(enc)
        end
      else
        s.gsub(/((?:%[0-9a-fA-F]{2})+)/) do
          [$1.delete('%')].pack('H*')
        end
      end
    end

    def unescape_backslash(s)
      if s.respond_to? :encoding
        enc = s.encoding
        s.gsub(/\\([0-7]{3})/) { $1.to_i(8).chr.force_encoding(enc) }.
          gsub(/\\x([\da-f]{2})/i) { $1.to_i(16).chr.force_encoding(enc) }
      else
        s.gsub(/\\([0-7]{3})/) { $1.to_i(8).chr }.
          gsub(/\\x([\da-f]{2})/i) { $1.to_i(16).chr }
      end
    end

    def escape_html(s)
      CGI.escapeHTML(s.to_s)
    end

    def unescape_html(s)
      CGI.unescapeHTML(s.to_s)
    end

    JSON_ESCAPE = { '&' => '\u0026', '>' => '\u003E', '<' => '\u003C' }

    def escape_json(s)
      s.to_s.gsub(/[&><]/) { |x| JSON_ESCAPE[x] }
    end

    def md5(s)
      Digest::MD5.hexdigest(s)
    end

    def sha256(s)
      Digest::SHA256.hexdigest(s)
    end

    def build_query(params)
      params.map do |k, v|
        if v.class == Array
          build_query(v.map { |x| [k, x] })
        else
          "#{escape(k.to_s)}=#{escape(v.to_s)}"
        end
      end.join('&')
    end

    def shell_filter(cmd, data)
      Open3.popen3(cmd) do |stdin, stdout, stderr|
        output = ''
        len = 0
        begin
          while len < data.length
            if found = IO.select([stdout], [stdin], nil, 0)
              len += stdin.write_nonblock(data[len..-1]) if found[1].first
              output << stdout.read_nonblock(1048576) if found[0].first
            end
          end
        rescue Errno::EPIPE
        end
        stdin.close
        begin
          output << stdout.read
        rescue Errno::EAGAIN
          retry
        end
        output
      end
    end
  end
end

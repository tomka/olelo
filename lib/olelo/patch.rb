module Olelo
  class PatchParser
    include Util

    class Handler
      include Util

      def initialize!
      end

      def finalize!
      end

      def begin!(src, dst)
      end

      def end!
      end

      def binary!
      end

      def no_changes!
      end

      def separator!
      end

      def addition!(line)
      end

      def deletion!(line)
      end

      def context!(line)
      end

      def line!(line)
        case line[0..0]
        when '+'
          addition!(line[1..-1])
        when '-'
          deletion!(line[1..-1])
        else
          context!(line[1..-1])
        end
      end
    end

    class Debugger
      def method_missing(name, *args)
        puts "#{name}: #{args.inspect}"
      end
    end

    class Adapter
      def initialize(adapter)
        @adapter = adapter
      end

      def method_missing(name, *args)
        @adapter.each {|a| a.send(name, *args) }
      end
    end

    def self.parse(patch, *h)
      h = h.size == 1 ? h[0] : Adapter.new(h)
      src = dst = nil
      state = :start
      h.initialize!
      patch.split("\n").each do |line|
        case state
        when :start
          case line
          when %r{^diff.* ("?a/.*"?) ("?b/.*"?)$}
            src, dst = unescape_path($1), unescape_path($2)
            state = :header
          when /^\+\+\+ (.*)/
            dst = unescape_path($1)
            state = :header
          when /^\-\-\- (.*)/
            src = unescape_path($1)
            state = :header
          end
        when :header
          case line
          when %r{^diff.* ("?a/.*"?) ("?b/.*"?)$}
            a, b = $1, $2
            h.begin!(src, dst)
            h.no_changes!
            h.end!
            src, dst = unescape_path(a), unescape_path(b)
          when /^\+\+\+ (.*)/
            dst = unescape_path($1)
          when /^\-\-\- (.*)/
            src = unescape_path($1)
          when /^Binary files (.*) and (.*) differ/
            src, dst = unescape_path($1), unescape_path($2)
            h.begin!(src, dst)
            h.binary!
            h.end!
            state = :start
          when /^@/
            state = :body
            h.begin!(src, dst)
          end
        when :body
          case line
          when %r{^diff.* ("?a/.*"?) ("?b/.*"?)$}
            src, dst = unescape_path($1), unescape_path($2)
            h.end!
            state = :header
          else
            line[0..0] == '@' ? h.separator! : h.line!(line)
          end
        end
      end
      case state
      when :header
        h.begin!(src, dst)
        h.no_changes!
        h.end!
      when :body
        h.end!
      end
      h.finalize!
      h
    end

    def self.unescape_path(path)
      path = unescape_backslash(path[1..-2]) if path.begins_with? '"'
      path == '/dev/null' ? nil : path[2..-1]
    end
  end

  class PatchSummary < PatchParser::Handler
    attr_reader :html

    def initialize(opts = {})
      @opts = opts
    end

    def initialize!
      @html = %{<table class="patch-summary"><thead><tr><th>#{:summary.t}</th><th class="add">+</th><th class="del">-</th></tr></thead><tbody>}
      @file = 0
    end

    def finalize!
      @html << "</tbody></table>"
    end

    def begin!(src, dst)
      @src, @dst = src, dst
      @add = @del = 0
    end

    def end!
      if @src && @dst
        if @src == @dst
          @html << %{<tr class="edit"><td class="name">#{link(escape_html @src)}</td><td class="add">#{@add}</td><td class="del">#{@del}</td></tr>}
        else
          text = "#{escape_html @src} &#8594; #{escape_html @dst}"
          @html << %{<tr class="move"><td class="name">#{link text}</td><td class="add">#{@add}</td><td class="del">#{@del}</td></tr>}
        end
      elsif @src
        @html << %{<tr class="delete"><td class="name">#{link(escape_html @src)}</td><td class="add">#{@add}</td><td class="del">#{@del}</td></tr>}
      else
        @html << %{<tr class="new"><td class="name">#{link(escape_html @dst)}</td><td class="add">#{@add}</td><td class="del">#{@del}</td></tr>}
      end
      @file += 1
    end

    def binary!
      @add = @del = '-'
    end

    def addition!(line)
      @add += 1
    end

    def deletion!(line)
      @del += 1
    end

    def link(text)
      @opts[:links] ? %{<a href="#patch-#{@file}">#{text}</a>} : text
    end
  end

  class PatchFormatter < PatchParser::Handler
    attr_reader :html

    STATE = {
      '+'  => '<span class="add">',
      '-'  => '<span class="del">',
      ' '  => ''
    }

    def initialize(opts = {})
      @opts = opts
    end

    def initialize!
      @html = ''
      @state = nil
      @file = 0
    end

    def begin!(src, dst)
      @html << '<table class="patch"'
      @html << %{ id="patch-#{@file}"} if @opts[:links]
      if @opts[:header]
        @html << '><thead><tr class="'
        if src && dst
          if src == dst
            @html << 'edit"><th>' << escape_html(src)
          else
            @html << 'move"><th>' << escape_html(src) << ' &#8594; ' << escape_html(dst)
          end
        elsif src
          @html << 'delete"><th>' << escape_html(src)
        else
          @html << 'new"><th>' << escape_html(dst)
        end
        @html << '</th></tr></thead><tbody><tr><td>'
      else
        @html << '><tbody><tr><td>'
      end
    end

    def end!
      @html << '</span>' if @state
      @state = nil
      @html << '</td></tr></tbody></table>'
      @file += 1
    end

    def binary!
      @html << :binary_file.t
    end

    def no_changes!
      @html << :no_changes.t
    end

    def separator!
      @html << '</span>' if @state
      @state = nil
      @html << '</td></tr><tr><td>'
    end

    def line!(line)
      ch = line[0..0]
      line = line[1..-1]
      if ch != '\\'
        if @state != ch
          @html << '</span>' if @state
          @html << STATE[ch]
        end
        @html << escape_html(line) << "\n"
        @state = ch == ' ' ? nil : ch
      end
    end
  end
end

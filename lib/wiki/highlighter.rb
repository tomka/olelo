require 'open3'
require 'cgi'
require 'wiki/extensions'
require 'digest'
require 'wiki/cache'

module Wiki
  module Highlighter
    def self.installed?
      !lexer_mapping.empty?
    end

    def self.cached_text(text, format, options = {})
      hash = Digest::MD5.hexdigest(text + format)
      Wiki::Cache.cache('highlight_text', hash, options) do
        text(text, format)
      end
    end

    def self.text(text, format)
      return CGI::escapeHTML(text) if !installed? 
      content = Open3.popen3("pygmentize -O encoding=utf8 -O linenos=table -f html -l '#{format}'") { |stdin, stdout, stderr|
        stdin << text
        stdin.close
        stdout.read
      }
      content.blank? ? CGI::escapeHTML(text) : content
    end

    def self.file(content, name)
      lexer = find_lexer(name)
      lexer ? text(content, lexer) : CGI::escapeHTML(content)
    end

    def self.supports?(filename)
      !!find_lexer(filename)
    end

    @mapping = nil

    def self.lexer_mapping
      if !@mapping
        @mapping = {}
        lexer = ''  
        output = `pygmentize -L lexer`
        output.split("\n").each do |line|
          if line =~ /^\* ([^:]+):$/
            lexer = $1.split(', ').first
          elsif line =~ /^   [^(]+ \(filenames ([^)]+)/
            $1.split(', ').each {|s| @mapping[s] = lexer }
          end
        end
      end
      @mapping
    end

    def self.find_lexer(name)
      pattern = lexer_mapping.keys.find {|pattern| File.fnmatch(pattern, name)}
      pattern && lexer_mapping[pattern]
    end

    private_class_method :lexer_mapping, :find_lexer
  end
end

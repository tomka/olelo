require 'open3'
require 'cgi'
require 'wiki/extensions'

module Wiki
  module Highlighter
    `pygmentize -V 2>&1 > /dev/null`
    @installed = $? == 0

    def self.installed?
      @installed
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

    private

    def self.lexer_mapping
      mapping = {}
      lexer = ''  
      output = `pygmentize -L lexer`
      output.split("\n").each do |line|
        if line =~ /^\* ([^:]+):$/
          lexer = $1.split(', ').first
        elsif line =~ /^   [^(]+ \(filenames ([^)]+)/
          $1.split(', ').each {|s| mapping[s] = lexer }
        end
      end
      mapping
    end

    def self.find_lexer(name)
      @mapping ||= lexer_mapping
      pattern = @mapping.keys.find {|pattern| File.fnmatch(pattern, name)}
      pattern && @mapping[pattern]
    end
  end
end

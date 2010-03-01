author      'Daniel Mendler'
description 'Pygments syntax highlighter'
autoload 'Open3', 'open3'

module Wiki::Pygments
  PROGRAM = 'pygmentize'
  RUN_OPTIONS = '-O encoding=utf8 -O linenos=table -O cssclass=pygments -f html -l'
  LOOKUP_OPTIONS = '-L lexer'

  def self.pygmentize(text, format)
    return pre(text) if lexer_mapping.empty? || !format
    content = Open3.popen3("#{PROGRAM} #{RUN_OPTIONS} '#{format}'") { |stdin, stdout, stderr|
      stdin << text
      stdin.close
      stdout.read
    }
    content.blank? ? pre(text) : content
  end

  def self.file_format(name)
    pattern = lexer_mapping.keys.find {|p| File.fnmatch(p, name)}
    pattern && lexer_mapping[pattern]
  end

  def self.pre(text)
    "<pre>#{Wiki.html_escape(text.strip)}</pre>"
  end

  def self.lexer_mapping
    if !@mapping
      @mapping = {}
      lexer = ''
      output = `#{PROGRAM} #{LOOKUP_OPTIONS}`
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

  private_class_method :pre, :lexer_mapping
end

class Wiki::Application
  assets 'pygments.css'

  hook(:after_style) do
    '<link rel="stylesheet" href="/_/utils/pygments.css" type="text/css"/>' if @context && @context.private[:pygmentize_used]
  end

  def pygmentize(code, format)
    @context.private[:pygmentize_used] = true if @context
    Pygments.pygmentize(code, format)
  end
end

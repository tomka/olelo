description    'Pygments syntax highlighter'
dependencies   'utils/assets', 'utils/shell'
export_scripts 'pygments.css'

module Olelo::Pygments
  include Util

  FORMAT_OPTIONS = %w(-O encoding=utf8 -O linenos=table -O cssclass=pygments -f html -l)

  def self.pygmentize(text, format)
    return pre(text) if !lexer_mapping.values.include?(format)
    options = FORMAT_OPTIONS + [format]
    content = Shell.pygmentize(*options).run(text)
    content.blank? ? pre(text) : content
  end

  def self.file_format(name)
    pattern = lexer_mapping.keys.find {|p| File.fnmatch(p, name)}
    pattern && lexer_mapping[pattern]
  end

  def self.pre(text)
    "<pre>#{escape_html(text.strip)}</pre>"
  end

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

  private_class_method :pre, :lexer_mapping
end

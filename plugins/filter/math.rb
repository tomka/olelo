description  'Math shortcuts \(1+1\), \[1+1\], $$1+1$$'
dependencies 'engine/filter'

Filter.create :math do |content|
  content.gsub!(/\$\$(.*?)\$\$/m, '<math display="inline">\1</math>')
  content.gsub!(/\\\((.*?)\\\)/m, '<math display="inline">\1</math>')
  content.gsub!(/\\\[(.*?)\\\]/m, '<math display="block">\1</math>')
  content
end

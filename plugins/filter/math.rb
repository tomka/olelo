author       'Daniel Mendler'
description  'Math shortcuts \(1+1\), \[1+1\], $$1+1$$'
dependencies 'engine/filter'

Filter.create :math do |content|
  content.gsub!(/\$\$(.*?)\$\$/m, '<math type="inline">\1</math>')
  content.gsub!(/\\\((.*?)\\\)/m, '<math type="inline">\1</math>')
  content.gsub!(/\\\[(.*?)\\\]/m, '<math type="block">\1</math>')
  content
end

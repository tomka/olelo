dependencies 'engine/filter'
author       'Daniel Mendler'
description  'Shortcut math tag filter'

Filter.create :math do |content|
  content.gsub!(/\$\$(.*?)\$\$/m, '<math>\1</math>')
  content.gsub!(/\\\((.*?)\\\)/m, '<math>\1</math>')
  content
end

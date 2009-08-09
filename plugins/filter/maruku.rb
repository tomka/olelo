author       'Daniel Mendler'
description  'Maruku/Markdown text filter'
dependencies 'engine/filter'
require      'maruku'

Filter.create :maruku do |content|
  Maruku.new(content).to_html
end

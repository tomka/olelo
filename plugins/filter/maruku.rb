author       'Daniel Mendler'
description  'Maruku/Markdown text filter'
dependencies 'engine/filter', 'gem:maruku'
autoload 'Maruku', 'maruku'

Filter.create :maruku do |content|
  Maruku.new(content).to_html
end

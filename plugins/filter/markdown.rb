author       'Daniel Mendler'
description  'Markdown text filter'
dependencies 'engine/filter'
require      'rdiscount'

Filter.create :markdown do |content|
  RDiscount.new(content).to_html
end

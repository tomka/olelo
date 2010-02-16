author       'Daniel Mendler'
description  'Markdown text filter'
dependencies 'engine/filter', 'gem:rdiscount'
autoload 'RDiscount', 'rdiscount'

Filter.create :markdown do |content|
  RDiscount.new(content, :filter_html).to_html
end

description  'Markdown text filter'
dependencies 'engine/filter'
require      'rdiscount'

Filter.create :markdown do |content|
  RDiscount.new(content, :filter_html).to_html
end

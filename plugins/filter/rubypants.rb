author       'Daniel Mendler'
description  'Filter which fixes punctuation'
dependencies 'engine/filter'
require      'rubypants'

Filter.create :rubypants do |content|
  RubyPants.new(content).to_html
end

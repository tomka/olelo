depends_on 'engine/filter'
require 'rubypants'

Filter.create :rubypants do |content|
  RubyPants.new(content).to_html
end

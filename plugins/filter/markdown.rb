depends_on 'engine/filter'
require 'rdiscount'

Filter.create :markdown do |content|
  RDiscount.new(content).to_html
end

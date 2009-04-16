depends_on 'engine/filter'
require 'maruku'

Filter.create :maruku do |content|
  Maruku.new(content).to_html
end

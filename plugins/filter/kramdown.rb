author       'Daniel Mendler'
description  'Kramdown markdown converter'
dependencies 'engine/filter'
require      'kramdown'

Filter.create :kramdown_html do |content|
  Kramdown::Document.new(content).to_html
end

Filter.create :kramdown_latex do |content|
  Kramdown::Document.new(content).to_latex
end

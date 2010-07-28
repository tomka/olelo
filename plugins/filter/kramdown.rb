description  'Kramdown markdown converter'
dependencies 'engine/filter'
require      'kramdown'

Filter.create :kramdown do |content|
  doc = Kramdown::Document.new(content)
  options[:latex] ? doc.to_latex : doc.to_html
end

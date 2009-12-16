author       'Daniel Mendler'
description  'Textile text filter'
dependencies 'engine/filter', 'gem:RedCloth'
autoload 'RedCloth', 'redcloth'

Filter.create :textile do |content|
  doc = RedCloth.new(content)
  doc.sanitize_html = true
  doc.to_html
end


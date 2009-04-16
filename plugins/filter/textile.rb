require 'redcloth'
depends_on 'engine/filter'

Filter.create :textile do |content|
  doc = RedCloth.new(content)
  doc.sanitize_html = true
  doc.to_html
end


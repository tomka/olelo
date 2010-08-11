description  'Textile text filter'
dependencies 'engine/filter'
require      'redcloth'

Filter.create :textile do |context, content|
  RedCloth.new(content, :sanitize_html).to_html
end

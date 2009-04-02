Wiki::Plugin.define 'filter/textile' do
  require 'redcloth'
  depends_on 'engine/filter'

  Wiki::Filter.create :textile do |content|
    doc = RedCloth.new(content)
    doc.sanitize_html = true
    doc.to_html
  end
end

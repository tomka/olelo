Wiki::Plugin.define 'filter/markdown' do
  depends_on 'engine/filter'
  require 'rdiscount'

  Wiki::Filter.create :markdown do |content|
    RDiscount.new(content).to_html
  end
end

Wiki::Plugin.define 'filter/maruku' do
  depends_on 'engine/filter'
  require 'maruku'

  Wiki::Filter.create :maruku do |content|
    Maruku.new(content).to_html
  end
end

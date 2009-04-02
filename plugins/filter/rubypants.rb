Wiki::Plugin.define 'filter/rubypants' do
  depends_on 'engine/filter'
  require 'rubypants'

  Wiki::Filter.create :rubypants do |content|
    RubyPants.new(content).to_html
  end
end

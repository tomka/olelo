Wiki::Plugin.define 'misc/rubypants' do
  require 'rubypants'
  load_after 'engine/*'

  Wiki::Engine.extend :creole, :markdown, :textile do
    append_filter do |page, content|
      [page, RubyPants.new(content).to_html]
    end
  end
end

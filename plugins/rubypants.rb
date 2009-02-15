Wiki::Plugin.define :rubypants do
  require 'rubypants'
  depends_on :creole

  Wiki::Engine.extend :creole do
    append :filter do |page, content|
      [page, RubyPants.new(content).to_html]
    end
  end
end

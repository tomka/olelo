Wiki::Plugin.define 'engine/markdown' do
  require 'rdiscount'

  Wiki::Mime.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain)) do |io|
    io.read(10) == '#!markdown'
  end

  Wiki::Engine.create(:markdown, 1, true) do
    accepts {|page| page.mime == 'text/x-markdown' }
    output do |page|
      content = page.content.sub(/^#!creole\s+/,'')
      RDiscount.new(content).to_html
    end
  end
end

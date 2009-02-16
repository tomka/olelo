Wiki::Plugin.define 'engine/html' do
  Wiki::Engine.create(:html, 3, true) do
    accepts {|page| page.mime.text? }
    output  {|page| "<pre>#{escape_html page.content}</pre>" }
    mime    {|page| page.mime }
  end
end

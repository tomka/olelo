Wiki::Plugin.define 'engine/preformatted' do
  Wiki::Engine.create(:preformatted, :priority => 3, :layout => true, :cacheable => true) do
    accepts {|page| page.mime.text? }
    output  {|context| "<pre>#{escape_html context.page.content}</pre>" }
    mime    {|page| page.mime }
  end
end

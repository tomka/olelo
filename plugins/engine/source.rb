author      'Daniel Mendler'
description 'Source engine'

Engine.create(:source, :priority => 3, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.text?; end
  def output(context); "<pre>#{escape_html context.page.content}</pre>"; end
  def mime(page); page.mime; end
end

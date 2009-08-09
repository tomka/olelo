author       'Daniel Mendler'
description  'Generates CSS from sass'

Engine.create(:css, :priority => 6, :layout => false, :cacheable => true) do
  def accepts?(page); page.mime == 'text/x-sass'; end
  def output(context); sass(context.page.content) end
  def mime(page); 'text/css'; end
end

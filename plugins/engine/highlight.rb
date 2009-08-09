author       'Daniel Mendler'
description  'Source code highlighting engine'
dependencies 'misc/pygments'

Engine.create(:highlight, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(page); Pygments.supports?(page.name); end
  def output(context); Pygments.pygmentize(context.page.content, :filename => context.page.name); end
end

description 'Download engine'
dependencies 'engine/engine'

Engine.create(:download, :priority => 999, :layout => false) do
  def accepts?(page); page.page?; end
  def output(context)
    context.response['Content-Disposition'] = 'attachment; filename="%s"' % context.page.safe_name
    context.page.content
  end
end

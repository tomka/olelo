description 'Download engine'
dependencies 'engine/engine'

Engine.create(:download, :priority => 999, :layout => false) do
  def output(context)
    context.response['Content-Disposition'] = 'attachment; filename="%s"' % context.page.safe_name
    context.page.content
  end
end

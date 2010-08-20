description 'Download engine'
dependencies 'engine/engine'

Engine.create(:download) do
  def accepts?(page); page.content; end
  def output(context)
    context.response['Content-Disposition'] = 'attachment; filename="%s"' % context.page.safe_name
    context.page.content
  end
end

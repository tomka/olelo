description 'Download engine'
dependencies 'engine/engine'

Engine.create(:download) do
  def accepts?(page); !page.content.empty?; end
  def output(context)
    name = context.page.root ? :root.t : context.page.name.gsub(/[^\w.\-_]/, '_')
    context.response['Content-Disposition'] = %{attachment; filename="#{name}"}
    context.page.content
  end
end

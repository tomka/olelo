description  'Text engine'
dependencies 'engine/engine'

# Text engine. Renders text content.
Engine.create(:text, :mime => 'text/plain; charset=utf-8', :cacheable => false, :cacheable => true) do
  def accepts?(page); page.mime.text?; end
  def output(context); context.page.content; end
end

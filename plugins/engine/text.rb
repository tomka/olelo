description  'Text engine'
dependencies 'engine/engine'

# Text engine. Renders text content.
Engine.create(:text, :mime => 'text/plain; charset=utf-8') do
  def accepts?(page); page.mime.text?; end
end

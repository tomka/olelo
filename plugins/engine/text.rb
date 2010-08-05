description  'Text engine'
dependencies 'engine/engine'

# Text engine. Renders text content.
Engine.create(:text, :priority => 999, :layout => false, :mime => 'text/plain; charset=utf-8') do
  def accepts?(page); page.mime.text?; end
end

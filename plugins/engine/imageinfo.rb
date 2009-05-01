require 'RMagick'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.mediatype == 'image'; end
  def output(context)
    @resource = context.page
    @image = Magick::Image.from_blob(@resource.content).first
    haml :imageinfo, :layout => false
  end
end

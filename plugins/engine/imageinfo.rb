require 'RMagick'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.mediatype == 'image'; end
  def output(context)
    @page = context.page
    @image = Magick::Image.from_blob(@page.content).first
    haml :imageinfo
  end
end

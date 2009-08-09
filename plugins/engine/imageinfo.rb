author      'Daniel Mendler'
description 'Image information engine'
require     'RMagick'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.mediatype == 'image'; end
  def output(context)
    @resource = context.page
    image = Magick::Image.from_blob(@resource.content).first
    @filesize = image.filesize
    @format = image.format
    @geometry = "#{image.columns}x#{image.rows}"
    image.destroy!
    haml :imageinfo, :layout => false
  end
end

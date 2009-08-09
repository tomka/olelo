author      'Daniel Mendler'
description 'Image rendering engine'
require     'RMagick'

Engine.create(:image, :priority => 2, :layout => false, :cacheable => true) do
  def svg?(page); page.mime.to_s =~ /svg/; end
  def accepts?(page); page.mime.mediatype == 'image'; end
  def mime(page); svg?(page) ? 'image/png' : page.mime; end

  def output(context)
    page = context.page
    if svg?(page) || context['geometry']
      image = Magick::Image.from_blob(page.content).first
      image.change_geometry(context['geometry']) { |w,h| image.resize!(w, h) } if context['geometry']
      image.format = 'png' if svg?(page)
      result = image.to_blob
      image.destroy!
      result
    else
      super
    end
  end
end

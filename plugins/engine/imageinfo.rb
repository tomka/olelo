Wiki::Plugin.define 'engine/imageinfo' do
  require 'RMagick'

  Wiki::Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
    accepts {|page| page.mime.mediatype == 'image' }
    output do |context|
      @page = context.page
      @image = Magick::Image.from_blob(@page.content).first
      haml :imageinfo
    end
  end
end

Wiki::Plugin.define 'engine/image' do
  require 'RMagick'

  Wiki::Engine.create(:image, :priority => 2, :layout => false, :cacheable => true) do
    def svg?(page)
      page.mime.to_s =~ /svg/
    end

    accepts {|page| page.mime.mediatype == 'image' }

    output do |page,params|
      if svg?(page) || params['geometry']
        image = Magick::Image.from_blob(page.content).first
        image.change_geometry(params['geometry']) { |w,h| image.resize!(w, h) } if params['geometry']
        image.format = 'png' if svg?(page)
        image.to_blob
      else
        super
      end
    end

    mime {|page| svg?(page) ? 'image/png' : page.mime }

  end
end

Wiki::Plugin.define 'engine/imageinfo' do
  Wiki::Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
    accepts {|page| page.mime.mediatype == 'image' }
    output do |page,params|
      "<img src=\"#{object_path(page, :output => 'image')}\"/>"
    end
  end
end

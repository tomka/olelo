author       'Daniel Mendler'
description  'Gallery engine'

class Wiki::Application
  assets 'gallery.css', 'gallery.js'

  hook(:after_style) do
    if @engine && @engine.name == 'gallery'
      '<link rel="stylesheet" href="/_/engine/gallery/gallery.css" type="text/css"/>'
    end
  end

  hook(:after_script) do
    if @engine && @engine.name == 'gallery'
      '<script src="/_/engine/gallery/gallery.js" type="text/javascript"></script>'
    end
  end

end

Engine.create(:gallery, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    per_page = 16
    @page = context.params[:curpage].to_i
    @tree = context.tree
    @images = @tree.pages.select {|page| page.mime.mediatype == 'image' }
    @pages = @images.size / per_page
    @images = @images[(@page * per_page) ... ((@page + 1) * per_page)].to_a
    haml :gallery, :layout => false
  end
end

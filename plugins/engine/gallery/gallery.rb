author       'Daniel Mendler'
description  'Gallery engine'
dependencies 'engine/engine'

class Wiki::Application
  assets 'gallery.css', 'script.js'

  after :style do
    if @engine && @engine.name == 'gallery'
      '<link rel="stylesheet" href="/_/engine/gallery/gallery.css" type="text/css"/>'
    end
  end

  after :script do
    if @engine && @engine.name == 'gallery'
      '<script src="/_/engine/gallery/script.js" type="text/javascript"></script>'
    end
  end

end

Engine.create(:gallery, :priority => 3, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    per_page = 16
    @curpage = context.params[:curpage].to_i
    @tree = context.tree
    @images = @tree.children.select {|page| page.page? && page.mime.image? }
    @pages = @images.size / per_page
    @images = @images[(@curpage * per_page) ... ((@curpage + 1) * per_page)].to_a
    render :gallery
  end
end

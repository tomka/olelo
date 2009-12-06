author       'Daniel Mendler'
description  'Gallery engine'

class Wiki::App

  static_files 'gallery.css', 'gallery.js'

  add_hook(:after_head) do
    if @engine && @engine.name == 'gallery'
      '<link rel="stylesheet" href="/sys/engine/gallery/gallery.css" type="text/css"/>'
    end
  end

  add_hook(:after_script) do
    if @engine && @engine.name == 'gallery'
      '<script src="/sys/engine/gallery/gallery.js" type="text/javascript"></script>'
    end
  end

end

Engine.create(:gallery, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @page = context[:page].to_i
    @tree = context.tree
    @images = @tree.pages.select {|page| page.mime.mediatype == 'image' }
    haml :gallery, :layout => false
  end
end

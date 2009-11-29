author       'Daniel Mendler'
description  'Gallery engine'

class Wiki::App

  public_files 'gallery.css', 'gallery.js'

  add_hook(:after_head) do
    if @engine && @engine.name == 'gallery'
      '<link rel="stylesheet" href="/sys/engine/gallery/gallery.css" type="text/css"/>' +
        '<script src="/sys/engine/gallery/gallery.js" type="text/javascript"></script>'
    end
  end

end

Engine.create(:gallery, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    puts context.inspect
    @page = context[:page].to_i
    @tree = context.tree
    @images = @tree.pages.select {|page| page.mime.mediatype == 'image' }
    haml :gallery, :layout => false
  end
end

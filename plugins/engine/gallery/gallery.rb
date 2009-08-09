author       'Daniel Mendler'
description  'Gallery engine'

Wiki::App.public_files 'jquery.galleriffic.js', 'loading.gif'

Engine.create(:gallery, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @tree = context.tree
    @images = @tree.pages.select {|page| page.mime.mediatype == 'image' }
    haml :gallery, :layout => false
  end
end

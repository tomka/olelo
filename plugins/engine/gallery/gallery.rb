description  'Gallery engine'
dependencies 'engine/engine', 'utils/asset_manager'

AssetManager.register_scripts '*.js', '*.css'

Engine.create(:gallery, :priority => 3, :layout => true, :cacheable => true, :hidden => true, :accepts => Tree::MIME) do
  def output(context)
    per_page = 16
    @page = context.params[:page].to_i
    @tree = context.tree
    @images = @tree.children.select {|page| page.page? && page.mime.image? }
    @last_page = @images.size / per_page
    @images = @images[(@page * per_page) ... ((@page + 1) * per_page)].to_a
    render :gallery
  end
end

__END__
@@ gallery.haml
- per_row = 4
= pagination(@tree, @last_page, @page, :output => 'gallery')
- if @images.empty?
  = :empty.t
- else
  %table#gallery-thumbs
    - @images.each_slice(per_row) do |row|
      %tr
        - row.each do |image|
          - thumb_path = resource_path(image, :output => 'image', :geometry => '100x>')
          - image_path = resource_path(image, :output => 'image', :geometry => '500x>')
          %td
            %a(href=image_path)
              %img(src=thumb_path alt='')
  #gallery-screen

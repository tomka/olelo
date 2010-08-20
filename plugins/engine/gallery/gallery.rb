description  'Gallery engine'
dependencies 'engine/engine', 'utils/asset_manager'

AssetManager.register_scripts '*.js', '*.css'

Engine.create(:gallery, :priority => 3, :layout => true, :hidden => true, :cacheable => true) do
  def accepts?(page); !page.children.empty?; end
  def output(context)
    per_page = 16
    @page_nr = context.params[:page].to_i
    @page = context.page
    @images = @page.children.select {|page| page.mime.image? }
    @last_page = @images.size / per_page
    @images = @images[(@page_nr * per_page) ... ((@page_nr + 1) * per_page)].to_a
    render :gallery
  end
end

__END__
@@ gallery.haml
- per_row = 4
= pagination(page_path(@page), @last_page, @page_nr, :output => 'gallery')
%table#gallery-thumbs
  - @images.each_slice(per_row) do |row|
    %tr
      - row.each do |image|
        - thumb_path = page_path(image, :output => 'image', :geometry => '100x>')
        - image_path = page_path(image, :output => 'image', :geometry => '500x>')
        %td
          %a(href=image_path)
            %img(src=thumb_path alt='')
  #gallery-screen

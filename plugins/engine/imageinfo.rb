author      'Daniel Mendler'
description 'Image information engine'
dependencies 'engine/image'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.image?; end
  def output(context)
    @page = context.page
    identify = shell_filter("#{Plugin['engine/image'].magick_prefix}identify -format '%m %h %w' -", context.page.content).split(' ')
    @type = identify[0]
    @geometry = "#{identify[1]}x#{identify[2]}"
    @exif = shell_filter('exif -m /dev/stdin 2>&1', context.page.content).split("\n").map {|line| line.split("\t") }
    @exif = nil if !@exif[0] || !@exif[0][1]
    render :info
  end
end

__END__

@@ info.haml
%p
  %a{:href => resource_path(@page, :output => 'image') }
    %img{:src=> resource_path(@page, :output => 'image', :geometry => '640x480>'), :alt=>@page.name}
%h3&= :information.t
%table.zebra
  %tbody
    %tr
      %td&= :name.t
      %td&= @page.name
    %tr
      %td&= :type.t
      %td&= @type
    %tr
      %td&= :geometry.t
      %td&= @geometry
    - if @page.version
      %tr
        %td&= :last_modified.t
        %td= date @page.version.date
      %tr
        %td&= :version.t
        %td.version&= @page.version
- if @exif
  %h3&= :exif.t
  %table.zebra
    %thead
      %tr
        %th&= :entry.t
        %th&= :value.t
    %tbody
      - @exif.each do |key, value|
        %tr
          %td&= key
          %td&= value

author      'Daniel Mendler'
description 'Image information engine'
dependencies 'engine/engine'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.mediatype == 'image'; end
  def output(context)
    require 'open3'
    @page = context.page
    identify = shell_filter("identify -format '%m %h %w' -", context.page.content).split(' ')
    @format = identify[0]
    @geometry = "#{identify[1]}x#{identify[2]}"
    @exif = shell_filter('exif -m /dev/stdin 2>&1', context.page.content).split("\n").map {|line| line.split("\t") }
    @exif = nil if !@exif[0] || !@exif[0][1]
    render :imageinfo
  end
end

author      'Daniel Mendler'
description 'Image information engine'
require     'open3'

Engine.create(:imageinfo, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime.mediatype == 'image'; end
  def output(context)
    @resource = context.page
    identify = Open3.popen3("identify -format '%m %h %w' -") { |stdin, stdout, stderr|
      stdin << context.page.content
      stdin.close
      stdout.read
    }.split(' ')
    @format = identify[0]
    @geometry = "#{identify[1]}x#{identify[2]}"
    @exif = Open3.popen3('exif -m /dev/stdin 2>&1') { |stdin, stdout, stderr|
      stdin << context.page.content rescue nil
      stdin.close
      stdout.read
    }.split("\n").map {|line| line.split("\t") }
    @exif = nil if !@exif[0] || !@exif[0][1]
    haml :imageinfo, :layout => false
  end
end

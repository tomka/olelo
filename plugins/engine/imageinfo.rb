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
    @exif = Open3.popen3('exif /dev/stdin 2>&1') { |stdin, stdout, stderr|
      stdin << context.page.content rescue nil
      stdin.close
      stdout.read
    }
    @exif = @exif.split("\n").select {|line| line.include?('|') }.map {|line| line.split(/\s*\|\s*/) }
    @exif.shift
    haml :imageinfo, :layout => false
  end
end

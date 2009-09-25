author      'Daniel Mendler'
description 'Image rendering engine'
require     'open3'

Engine.create(:image, :priority => 2, :layout => false, :cacheable => true) do
  def svg?(page); page.mime.to_s =~ /svg/; end
  def accepts?(page); page.mime.mediatype == 'image'; end
  def mime(page); svg?(page) ? 'image/png' : page.mime; end

  def output(context)
    page = context.page
    if svg?(page) || context['geometry']
      geometry = context['geometry']
      cmd = 'convert -limit memory 1048576 -limit area 1048576 -limit map 1048576'
      cmd << " -resize '#{context['geometry']}'" if geometry =~ /^(\d+)?x(\d+)?[%!<>]*$/
      cmd << ' - PNG:-'
      Open3.popen3(cmd) { |stdin, stdout, stderr|
        stdin << page.content
        stdin.close
        stdout.read
      }
    else
      super
    end
  end
end

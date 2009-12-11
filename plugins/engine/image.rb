author      'Daniel Mendler'
description 'Image rendering engine'
require     'open3'

setup do
  cpu_count = `cat /proc/cpuinfo | grep processor | wc -l`.to_i rescue 1
  $image_semaphore = Semaphore.new(cpu_count)
end

Engine.create(:image, :priority => 5, :layout => false, :cacheable => true) do
  def svg?(page); page.mime.to_s =~ /svg/; end
  def ps?(page); page.mime.to_s =~ /postscript/; end
  def pdf_or_ps?(page); page.mime == 'application/pdf' || ps?(page); end
  def accepts?(page); page.mime.mediatype == 'image' || pdf_or_ps?(page); end

  def mime(page)
    if pdf_or_ps?(page)
      'image/jpeg'
    elsif svg?(page)
      'image/png'
    else
      page.mime
    end
  end

  def output(context)
    page = context.page
    geometry = context['geometry']
    if pdf_or_ps?(page)
      curpage = context['curpage'].to_i + 1
      cmd = ''
      if page.mime == 'application/x-bzpostscript'
        cmd = 'bunzip2 -c - | '
      elsif page.mime == 'application/x-gzpostscript'
        cmd = 'gunzip -c - | '
      end
      if ps?(page)
        cmd << "psselect -p#{curpage} /dev/stdin /dev/stdout | "
        cmd << "gs -sDEVICE=jpeg -sOutputFile=- -r150 -dBATCH  -dNOPAUSE -q - | "
      else
        cmd << "gs -sDEVICE=jpeg -sOutputFile=- -dFirstPage=#{curpage} -dLastPage=#{curpage} -r150 -dBATCH  -dNOPAUSE -q - | "
      end
      cmd << 'convert -depth 8 -quality 50 '
      cmd << " -resize '#{geometry}'" if geometry =~ /^(\d+)?x(\d+)?[%!<>]*$/
      cmd << ' - JPEG:-'
      convert(page, cmd)
    elsif svg?(page) || geometry
      cmd = 'convert'
      cmd << " -resize '#{geometry}'" if geometry =~ /^(\d+)?x(\d+)?[%!<>]*$/
      cmd << ' - '
      cmd << (page.mime.to_s == 'image/jpeg' ? 'JPEG:-' : 'PNG:-')
      convert(page, cmd)
    else
      super
    end
  end

  def convert(page, cmd)
    $image_semaphore.synchronize do
      Open3.popen3(cmd) { |stdin, stdout, stderr|
        stdin << page.content
        stdin.close
        stdout.read
      }
    end
  end
end

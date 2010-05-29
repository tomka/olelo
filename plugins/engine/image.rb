author      'Daniel Mendler'
description 'Image rendering engine'
dependencies 'engine/engine', 'utils/semaphore'

cpu_count = `cat /proc/cpuinfo | grep processor | wc -l`.to_i rescue 1
@semaphore = Semaphore.new(cpu_count)
def semaphore; @semaphore; end

Engine.create(:image, :priority => 5, :layout => false, :cacheable => true) do
  def svg?(page); page.mime.to_s =~ /svg/; end
  def ps?(page); page.mime.to_s =~ /postscript/; end
  def pdf_or_ps?(page); page.mime == 'application/pdf' || ps?(page); end
  def accepts?(page); page.mime.image? || pdf_or_ps?(page); end

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
    geometry = context.params[:geometry]
    trim = context.params[:trim]
    if pdf_or_ps?(page)
      curpage = context.params[:curpage].to_i + 1
      cmd = case page.mime.to_s
            when /bz/
              'bunzip2 | '
            when /gz/
              'gunzip | '
            else
              ''
            end
      if ps?(page)
        cmd << "psselect -p#{curpage} /dev/stdin /dev/stdout | "
        cmd << "gs -sDEVICE=jpeg -sOutputFile=- -r200 -dBATCH -dNOPAUSE -q - | "
      else
        cmd << "gs -sDEVICE=jpeg -sOutputFile=- -dFirstPage=#{curpage} -dLastPage=#{curpage} -r200 -dBATCH -dNOPAUSE -q - | "
      end
      cmd << 'convert -depth 8 -quality 50 '
      cmd << ' -trim' if trim
      cmd << " -resize '#{geometry}'" if geometry =~ /^(\d+)?x?(\d+)?[%!<>]*$/
      cmd << ' - JPEG:-'
      convert(page, cmd)
    elsif svg?(page) || geometry || trim
      cmd = 'convert'
      cmd << ' -trim' if trim
      cmd << " -resize '#{geometry}'" if geometry =~ /^(\d+)?x?(\d+)?[%!<>]*$/
      cmd << ' - '
      cmd << (page.mime.to_s == 'image/jpeg' ? 'JPEG:-' : 'PNG:-')
      convert(page, cmd)
    else
      super
    end
  end

  def convert(page, cmd)
    Plugin.current.semaphore.synchronize do
      shell_filter(cmd, page.content)
    end
  end
end

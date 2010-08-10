description 'Image rendering engine'
dependencies 'engine/engine', 'utils/semaphore'

cpu_count = `cat /proc/cpuinfo | grep processor | wc -l`.to_i rescue 1
@semaphore = Semaphore.new(cpu_count)
def semaphore; @semaphore; end

@magick_prefix = if (`gm -version` rescue '').include?('GraphicsMagick')
                   'gm '
                 elsif (`convert -version` rescue '').include?('ImageMagick')
                   ''
                 else
                   raise 'GraphicsMagick or ImageMagick not found'
                 end
def magick_prefix; @magick_prefix.dup; end

Engine.create(:image, :priority => 5, :cacheable => true) do
  def svg?(page); page.mime.to_s =~ /svg/; end
  def ps?(page); page.mime.to_s =~ /postscript/; end
  def pdf_or_ps?(page); page.mime == 'application/pdf' || ps?(page); end
  def accepts?(page); page.mime.image? || pdf_or_ps?(page); end

  def output(context)
    page = context.page
    geometry = context.params[:geometry]
    trim = context.params[:trim]
    if pdf_or_ps?(page)
      page_nr = context.params[:page].to_i + 1
      cmd = case page.mime.to_s
            when /bz/
              'bunzip2 | '
            when /gz/
              'gunzip | '
            else
              ''
            end
      if ps?(page)
        cmd << "psselect -p#{page_nr} /dev/stdin /dev/stdout | "
        cmd << "gs -sDEVICE=jpeg -sOutputFile=- -r200 -dBATCH -dNOPAUSE -q - | "
      else
        cmd << "gs -sDEVICE=jpeg -sOutputFile=- -dFirstPage=#{page_nr} -dLastPage=#{page_nr} -r200 -dBATCH -dNOPAUSE -q - | "
      end
      cmd << Plugin.current.magick_prefix << 'convert -depth 8 -quality 50 '
      cmd << ' -trim' if trim
      cmd << " -resize '#{geometry}'" if geometry =~ /^(\d+)?x?(\d+)?[%!<>]*$/
      cmd << ' - JPEG:-'
      context.response['Content-Type'] = 'image/jpeg'
      convert(page, cmd)
    elsif svg?(page) || geometry || trim
      cmd = Plugin.current.magick_prefix << 'convert'
      cmd << ' -trim' if trim
      cmd << " -resize '#{geometry}'" if geometry =~ /^(\d+)?x?(\d+)?[%!<>]*$/
      cmd << ' - '
      cmd << (page.mime.to_s == 'image/jpeg' ? 'JPEG:-' : 'PNG:-')
      context.response['Content-Type'] = 'image/png'
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

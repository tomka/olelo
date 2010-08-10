description 'Image rendering engine'
dependencies 'engine/engine', 'utils/imagemagick'

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
      page_nr = context.params[:page].to_i
      cmd = ImageMagick.new
      if ps?(page)
        cmd.cmd($1 == 'gz' ? 'gunzip' : 'bunzip2') if page.mime.to_s =~ /(bz|gz)/
        cmd.psselect "-p#{page_nr + 1}"
        cmd.gs '-sDEVICE=jpeg -sOutputFile=- -r144 -dBATCH -dNOPAUSE -q -'
      end
      cmd.convert('-depth 8 -quality 50') do |args|
        args << '-trim' if trim
        args << "-resize '#{geometry}'" if geometry =~ /^(\d+)?x?(\d+)?[%!<>]*$/
        if ps?(page)
          args << '-'
        else
          args << "-density 144 -[#{page_nr}]"
        end
        args << 'JPEG:-'
      end
      context.response['Content-Type'] = 'image/jpeg'
      cmd.run(page.content)
    elsif svg?(page) || geometry || trim
      cmd = ImageMagick.convert do |args|
        args << '-trim' if trim
        args << "-resize '#{geometry}'" if geometry =~ /^(\d+)?x?(\d+)?[%!<>]*$/
        args << ' - ' << (page.mime.to_s == 'image/jpeg' ? 'JPEG:-' : 'PNG:-')
      end
      context.response['Content-Type'] = 'image/png'
      cmd.run(page.content)
    else
      super
    end
  end
end

author      'Daniel Mendler'
description 'Document browser engine'
dependencies 'engine/engine'
require 'open3'

Engine.create(:documentbrowser, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime == 'application/pdf' || page.mime.to_s =~ /postscript/; end
  def output(context)
    @page = context.page
    @pages = 0
    if @page.mime == 'application/pdf'
      while @page.content =~ %r{^/Count\s+(\d+)$}
        @pages += $1.to_i
      end
      @pages -= 1
    else
      content = @page.content
      if @page.mime.to_s =~ /(gz|bz)/
        content = Open3.popen3($1 == 'gz' ? 'gunzip' : 'bunzip2') { |stdin, stdout, stderr|
          stdin << content
          stdin.close
          stdout.read
        }
      end
      @pages = $1.to_i - 1 if content =~ /^%%Pages:\s+(\d+)$/
    end
    @pages = 0 if @pages < 0
    @curpage = context.params[:curpage].to_i
    render :documentbrowser
  end
end

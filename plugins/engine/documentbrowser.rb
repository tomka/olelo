author      'Daniel Mendler'
description 'Document browser engine'
dependencies 'engine/engine'

Engine.create(:documentbrowser, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(page); page.mime == 'application/pdf' || page.mime.to_s =~ /postscript/; end
  def output(context)
    @page = context.page
    @pages = 0
    content = @page.content
    if @page.mime == 'application/pdf'
      content.scan %r{/Type\s*/Pages.*?/Count\s*(\d+)}m do
        @pages += $1.to_i
      end
      @pages -= 1
    else
      if @page.mime.to_s =~ /(gz|bz)/
        content = shell_filter($1 == 'gz' ? 'gunzip -c' : 'bunzip2 -c', content)
      end
      @pages = $1.to_i - 1 if content =~ /^%%Pages:\s+(\d+)$/
    end
    @pages = 0 if @pages < 0
    @curpage = context.params[:curpage].to_i
    render :documentbrowser
  end
end

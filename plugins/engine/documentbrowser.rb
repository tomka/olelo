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
    render :browser
  end
end

__END__

@@ browser.haml
= pagination(@page, @pages, @curpage, :output => 'documentbrowser')
%p
  %img#pdf{:src=> resource_path(@page, :output => 'image', :geometry => '480x>', :trim => 1, :curpage => @curpage)}
= pagination(@page, @pages, @curpage, :output => 'documentbrowser')
%h3&= :information.t
%table.zebra
  %tbody
    %tr
      %td&= :name.t
      %td&= @page.name
    - if @page.version
      %tr
        %td&= :last_modified.t
        %td= date @page.version.date
      %tr
        %td&= :version.t
        %td.version= @page.version
    %tr
      %td&= :type.t
      %td #{@page.mime.comment} (#{@page.mime})
    %tr
      %td&= :download.t
      %td
        %a{:href=> resource_path(@page, :output => 'download')} Download File

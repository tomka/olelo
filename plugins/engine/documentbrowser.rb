description 'Document browser engine'
dependencies 'engine/engine'

Engine.create(:documentbrowser, :priority => 1, :layout => true, :cacheable => true, :accepts => 'application/pdf|postscript') do
  def output(context)
    @page = context.page
    @last_page = 0
    content = @page.content
    if @page.mime == 'application/pdf'
      content.scan %r{/Type\s*/Pages.*?/Count\s*(\d+)}m do
        @last_page += $1.to_i
      end
      @last_page -= 1
    else
      if @page.mime.to_s =~ /(gz|bz)/
        content = shell_filter($1 == 'gz' ? 'gunzip -c' : 'bunzip2 -c', content)
      end
      @last_page = $1.to_i - 1 if content =~ /^%%Pages:\s+(\d+)$/
    end
    @last_page = 0 if @last_page < 0
    @page_nr = context.params[:page].to_i
    render :browser
  end
end

__END__

@@ browser.haml
= pagination(@page, @last_page, @page_nr, :output => 'documentbrowser')
%p
  %img#pdf{:src=> resource_path(@page, :output => 'image', :geometry => '480x>', :trim => 1, :page => @page_nr)}
= pagination(@page, @last_page, @page_nr, :output => 'documentbrowser')
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

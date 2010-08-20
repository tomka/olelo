description 'Page information engine'
dependencies 'engine/engine'

Engine.create(:pageinfo, :priority => 4, :layout => true, :cacheable => true) do
  def output(context)
    @page = context.page
    render :info
  end
end

__END__
@@ info.haml
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
    - if @page.content
      %tr
        %td&= :download.t
        %td
          %a{:href=> page_path(@page, :output => 'download')}&= :download.t

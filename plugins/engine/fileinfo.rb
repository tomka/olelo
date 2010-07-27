author      'Daniel Mendler'
description 'File information engine'
dependencies 'engine/engine'

Engine.create(:fileinfo, :priority => 4, :layout => true, :cacheable => true) do
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
    %tr
      %td&= :download.t
      %td
        %a{:href=> resource_path(@page, :output => 'download')} Download File

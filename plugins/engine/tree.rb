description  'Tree engine'
dependencies 'engine/engine'

Engine.create(:tree, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(page); !page.children.empty?; end
  def output(context)
    @page_nr = context.params[:page].to_i
    per_page = 20
    @page = context.page
    @last_page = @page.children.size / per_page
    @children = @page.children[(@page_nr * per_page) ... ((@page_nr + 1) * per_page)].to_a
    render :tree
  end
end

AssetManager.register_assets 'tree.haml'

__END__

@@ tree.haml
!= pagination(page_path(@page), @last_page, @page_nr, :output => 'tree')
%table#tree-table
  %thead
    %tr
      %th= :name.t
      %th= :last_modified.t
      %th= :author.t
      %th= :comment.t
      %th= :actions.t
  %tbody
    - @children.each do |child|
      - classes = child.children.empty? ? 'page' : 'tree'
      - if !child.extension.empty?
        - classes << " file-type-#{child.extension}"
      %tr
        %td.link
          %a{:href=>page_path(child), :class => classes}= child.name
        %td!= date(child.version.date)
        %td= truncate(child.version.author.name, 30)
        %td= truncate(child.version.comment, 30)
        %td.actions
          %a.action-edit{:href=>action_path(child, :edit), :title => :edit.t}= :edit.t
          %a.action-history{:href=>action_path(child, :history), :title => :history.t}= :history.t
          %a.action-move{:href=>action_path(child, :move), :title => :move.t}= :move.t
          %a.action-delete{:href=>action_path(child, :delete), :title => :delete.t}= :delete.t
!= pagination(page_path(@page), @last_page, @page_nr, :output => 'tree')

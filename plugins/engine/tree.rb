author      'Daniel Mendler'
description 'Tree engine'
dependencies 'engine/engine'

Engine.create(:tree, :priority => 2, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @curpage = context.params[:curpage].to_i
    per_page = 20
    @tree = context.tree
    @pages = @tree.children.size / per_page
    @children = @tree.children[(@curpage * per_page) ... ((@curpage + 1) * per_page)].to_a
    render :tree
  end
end

__END__

@@ tree.haml
= pagination(@tree, @pages, @curpage, :output => 'tree')
%table#tree-table
  %thead
    %tr
      %th= :name.t
      %th= :last_modified.t
      %th= :author.t
      %th= :comment.t
      %th= :actions.t
  %tbody
    - if @children.empty?
      %tr
        %td{:colspan=>5}= :empty.t
    - else
      - @children.each do |child|
        - classes = child.tree? ? 'tree' : 'page'
        - if child.page? && !child.extension.empty?
          - classes << " file-type-#{child.extension}"
        %tr
          %td.link
            %a{:href=>resource_path(child), :class => classes}= child.name
          %td= date(child.version.date)
          %td= child.version.author.name.truncate(30)
          %td&= child.version.comment.truncate(30)
          %td.actions
            - if child.page?
              %a.action-edit{:href=>action_path(child, :edit), :title => :edit.t}= :edit.t
            %a.action-history{:href=>action_path(child, :history), :title => :history.t}= :history.t
            %a.action-move{:href=>action_path(child, :move), :title => :move.t}= :move.t
            %a.action-delete{:href=>action_path(child, :delete), :title => :delete.t}= :delete.t
= pagination(@tree, @pages, @curpage, :output => 'tree')

author      'Daniel Mendler'
description 'Tree engine'
dependencies 'engine/engine'

Engine.create(:tree, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @page = context.params[:curpage].to_i
    per_page = 20
    @tree = context.tree
    @pages = @tree.children.size / per_page
    @children = @tree.children[(@page * per_page) ... ((@page + 1) * per_page)].to_a
    render :tree
  end
end

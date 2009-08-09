author      'Daniel Mendler'
description 'Tree engine'

Engine.create(:tree, :priority => 1, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @tree = context.tree
    haml :tree, :layout => false
  end
end

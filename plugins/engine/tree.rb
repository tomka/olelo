Engine.create(:tree, :priority => 4, :layout => true, :cacheable => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @tree = context.tree
    haml :tree, :layout => false
  end
end

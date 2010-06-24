author      'Daniel Mendler'
description 'Index page engine'
dependencies 'engine/engine'

# Engine which redirects to non-existing index page
Engine.create(:create_index_page, :priority => 2, :layout => true) do
  def accepts?(resource)
    resource.tree? && !Page.find(resource.path/Config.index_page)
  end

  def output(context)
    throw :redirect, (context.resource.path/Config.index_page).urlpath
  end
end

# Engine which shows index page
Engine.create(:index_page, :priority => 1, :layout => true) do
  def accepts?(resource)
    resource.tree? && Page.find(resource.path/Config.index_page)
  end

  def output(context)
    page = Page.find!(context.resource.path/Config.index_page)
    engine = Engine.find(page, :layout => true)
    if engine
      engine.cached_output(context.subcontext(:engine => engine, :resource => page))
    else
      %{<span class="error">#{:engine_not_available.t(:page => page.name, :type => "#{page.mime.comment} (#{page.mime})", :engine => nil)}</span>}
    end
  end
end

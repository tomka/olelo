author      'Daniel Mendler'
description 'Discussion pages'

class Wiki::Application
  hook :layout do |name, doc|
    if @resource && !@resource.namespace.metadata?
      if @resource.namespace.name == :discussion
        doc.css('#menu .wiki').each do |list|
          list << %{<li><a class="action-page" href="#{@resource.namespace_path(Namespace.main).urlpath}">#{:page.t}</a></li>}
        end
      elsif @resource.namespace.name == :main
        doc.css('#menu .wiki').each do |list|
          list << %{<li><a class="action-discussion" href="#{@resource.namespace_path(Namespace.page(:discussion)).urlpath}">#{:discussion.t}</a></li>}
        end
      end
    end
  end
end

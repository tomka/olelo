depends_on 'filter/tag'

class Wiki::App
  add_hook(:before_content) do
    return nil if !@resource || !params[:redirect]
    "<em>&#8594; Redirected from <a href=\"#{action_path(params[:redirect], :edit)}\">#{params[:redirect].cleanpath}</a></em>"
  end
end

Tag.define(:redirect, :requires => :href) do |context, attrs, content|
  path = resource_path(context.page, :path => attrs['href'], :redirect => context.page.path)
  if path == resource_path(context.page)
    "Invalid redirect to #{path}"
  elsif context.page.saved?
    throw :redirect, path
  else
    "Redirect to #{path}"
  end
end

dependencies 'filter/tag'
author       'Daniel Mendler'
description  'Support for page redirects'

class Wiki::App
  add_hook(:before_content) do
    "<em>&#8594; Redirected from <a href=\"#{action_path(params[:redirect], :edit)}\">#{params[:redirect].cleanpath}</a></em>" if @resource && params[:redirect]
  end
end

Tag.define(:redirect, :requires => :href) do |context, attrs, content|
  path = resource_path(context.page, :path => attrs['href'], :redirect => context['redirect'] || context.page.path)
  if path == resource_path(context.page)
    "Invalid redirect to #{path}"
  elsif context.page.modified?
    "Redirect to #{path}"
  else
    throw :redirect, path
  end
end

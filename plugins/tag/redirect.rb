author       'Daniel Mendler'
description  'Support for page redirects'
dependencies 'filter/tag'

class Wiki::App
  hook(:before_content) do
    if params[:redirect]
      links = [params[:redirect]].flatten.map do |link|
        %{<a href="#{Wiki.html_escape action_path(link, :edit)}">#{Wiki.html_escape link.cleanpath}</a>}
      end.join(' &#8594; ')
    "<p>Redirected from #{links} &#8594; \xE2\xA6\xBF</p>"
    end
  end
end

Tag.define(:redirect, :requires => :path) do |context, attrs, content|
  path = resource_path(context.page, :path => attrs[:path])
  list = (context.params[:redirect] ||= [])
  if list.include?(path)
    "Invalid redirect to #{path}"
  elsif context.page.modified?
    "Redirect to #{path}"
  else
    list << resource_path(context.page)
    throw :redirect, resource_path(context.page, :path => attrs[:path], 'redirect[]' => list)
  end
end

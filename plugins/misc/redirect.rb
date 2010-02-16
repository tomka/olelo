author       'Daniel Mendler'
description  'Support for page redirects'

class Wiki::App
  hook(:before_content) do
    if params[:redirect]
      links = [params[:redirect]].flatten.map do |link|
        %{<a href="#{Wiki.html_escape action_path(link, :edit)}">#{Wiki.html_escape link.cleanpath}</a>}
      end.join(' &#8594; ')
    "<p>Redirected from #{links} &#8594; \xE2\xA6\xBF</p>"
    end
  end

  hook(:before_page_show, 1000) do
    metadata = @resource.metadata
    if metadata[:redirect]
      path = resource_path(@resource, :path => metadata[:redirect])
      list = (params[:redirect] ||= [])
      if list.include?(path)
        raise RuntimeError, "Invalid redirect to #{path}"
      else
        list << resource_path(@resource)
        p = params.merge({ :path => metadata[:redirect], 'redirect[]' => list})
        p.delete(:redirect)
        redirect resource_path(@resource, p)
      end
    end
  end
end

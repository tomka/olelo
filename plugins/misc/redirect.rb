description 'Support for page redirects'

class Wiki::Application
  hook :layout do |name, doc|
    if params[:redirect]
      links = [*params[:redirect]].map do |link|
        %{<a href="#{escape_html action_path(link, :edit)}">#{escape_html link.cleanpath}</a> → }
      end.join
      doc.css('#content').children.before("<p>Redirected from #{links} ◉</p>")
    end
  end

  before(:show, 1) do
    metadata = @resource.metadata
    if metadata[:redirect]
      path = resource_path(@resource, :path => metadata[:redirect])
      list = (params[:redirect] ||= [])
      if list.include?(path)
        raise ArgumentError, "Invalid redirect to #{path}"
      else
        list << resource_path(@resource)
        p = params.merge({ :path => metadata[:redirect], 'redirect[]' => list})
        p.delete(:redirect)
        redirect resource_path(@resource, p)
      end
    end
  end
end

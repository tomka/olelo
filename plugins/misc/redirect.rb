author       'Daniel Mendler'
description  'Support for page redirects'

class Wiki::Application
  hook :layout do |name, doc|
    if params[:redirect]
      html = builder do
        p_ {
          text 'Redirected from '
          [params[:redirect]].flatten.each do |link|
            a link.cleanpath, :href => action_path(link, :edit)
            text ' → '
          end
          text '◉'
        }
      end
      doc.css('#content').children.before(html)
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

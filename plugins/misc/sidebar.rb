description  'Basic sidebar implementation'
dependencies 'engine/engine'

class Olelo::Application
  hook :layout do |name, doc|
    doc.css('#sidebar').first << if page = Page.find(Config.sidebar_page)
      Cache.cache("sidebar-#{page.version}", :update => request.no_cache?, :defer => true) do |context|
        begin
          Engine.find!(page, :layout => true).output(Context.new(:page => page))
        rescue Engine::NotAvailable => ex
          %{<span class="error">#{escape_html ex.message}</span>}
        end
      end
    else
      %{<a href="/#{Config.sidebar_page}/new">#{:create_page.t(:page => Config.sidebar_page)}</a>}
    end
  end
end

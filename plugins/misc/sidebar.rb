description  'Basic sidebar implementation'
dependencies 'engine/engine'

class Olelo::Application
  hook :layout do |name, doc|
    doc.css('#sidebar').first << if page = Page.find(Config.sidebar_page)
      Cache.cache("sidebar-#{page.version}", :update => request.no_cache?, :defer => true) do |context|
        engine = Engine.find(page, :layout => true)
        if engine
          engine.output(Context.new(:page => page))
        else
          %{<span class="error">#{:engine_not_available.t(:page => page.title, :type => "#{page.mime.comment} (#{page.mime})", :engine => nil)}</span>}
        end
      end
    else
      %{<a href="/#{Config.sidebar_page}/new">#{:create_page.t(:page => Config.sidebar_page)}</a>}
    end
  end
end

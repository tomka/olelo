description  'Basic sidebar implementation'
dependencies 'engine/engine'

class Olelo::Application
  hook :layout do |name, doc|
    doc.css('#sidebar').first << if page = Page.find(Config.sidebar_page)
      Cache.cache("sidebar-#{page.version}", :update => request.no_cache?) do |cache|
        engine = Engine.find(page, :layout => true)
        if engine
          cache.disable! if !engine.cacheable?
          engine.output(Context.new(:engine => engine, :logger => logger, :resource => page))
        else
          %{<span class="error">#{:engine_not_available.t(:page => page.name, :type => "#{page.mime.comment} (#{page.mime})", :engine => nil)}</span>}
        end
      end
    else
      %{<a href="/#{Config.sidebar_page}/new">#{:create_page.t(:page => Config.sidebar_page)}</a>}
    end
  end
end

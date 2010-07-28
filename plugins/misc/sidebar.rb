description  'Basic sidebar implementation'
dependencies 'engine/engine'

class Wiki::Application
  get '/_/sidebar' do
    if page = Page.find(Config.sidebar_page)
      engine = Engine.find(page, :layout => true)
      if engine
        #cache_control :etag => page.version, :last_modified => page.version.date
        cache_control :max_age => 60

        context = Context.new(:app      => self,
                              :request  => request,
                              :response => response,
                              :logger   => logger,
                              :resource => page,
                              :params   => params,
                              :engine   => engine)
        engine.cached_output(context)
      else
        %{<span class="error">#{:engine_not_available.t(:page => page.name, :type => "#{page.mime.comment} (#{page.mime})", :engine => nil)}</span>}
      end
    else
      %{<a href="/#{Config.sidebar_page}/new">#{:create_page.t(:page => Config.sidebar_page)}</a>}
    end
  end
end

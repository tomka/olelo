author      'Daniel Mendler'
description 'Basic sidebar implementation'

class Wiki::App
  get '/_/sidebar' do
    if page = Page.find(repository, Config.sidebar_page)
      engine = Engine.find(page, :layout => true)
      if engine
        #cache_control :etag => page.commit.sha, :last_modified => page.latest_commit.date
        cache_control :max_age => 60

        engine.response(:request => request,
                        :response => response,
                        :logger => logger,
                        :resource => page,
                        :params => params)
      else
        %{<span class="error">#{:no_engine_found.t(:page => page.name)}</span>}
      end
    else
      %{<a href="/#{Config.sidebar_page}/new">#{:create_page.t(:page => Config.sidebar_page)}</a>}
    end
  end
end

author      'Daniel Mendler'
description 'Basic sidebar implementation'

class Wiki::App
  get '/_/sidebar' do
    safe_output do
      with_hooks :sidebar do
        if page = Page.find(repository, :sidebar.t)
          engine = Engine.find!(page)
          if engine.layout?
            #cache_control :etag => page.commit.sha, :last_modified => page.latest_commit.date
            cache_control :max_age => 60

            engine.response(:request => request,
                            :response => response,
                            :logger => @logger,
                            :resource => page,
                            :params => params)
          else
            %{<span class="error">#{:no_engine_found.t(:page => page.name)}</span>}
          end
        else
          %{<a href="/#{:sidebar.t}/new">#{:create_sidebar.t}</a>}
        end
      end.to_s
    end
  end
end

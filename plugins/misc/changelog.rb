require 'rss/maker'

class Wiki::App
  add_hook(:after_head) do
    if @resource
      %Q{<link rel="alternate" href="#{(@resource.path/'changelog.rss').urlpath}" type="application/rss+xml" title="Changelog"/>}
    end
  end

  get '/changelog.rss', '/:path/changelog.rss' do
    resource = Resource.find!(@repo, params[:path])
    cache_control :etag => resource.latest_commit.sha, :last_modified => resource.latest_commit.date

    content_type 'application/rss+xml', :charset => 'utf-8'
    content = RSS::Maker.make('2.0') do |rss|
      rss.channel.title = Config.title
      rss.channel.link = request.scheme + '://' +  (request.host + ':' + request.port.to_s)
      rss.channel.description = Config.title + ' Changelog'
      rss.items.do_sort = true
      resource.history.each do |commit|
        i = rss.items.new_item
        i.title = commit.message
        i.link = request.scheme + '://' + (request.host + ':' + request.port.to_s)/resource.path/commit.sha
        i.date = commit.date
      end
    end
    content.to_s
  end
end

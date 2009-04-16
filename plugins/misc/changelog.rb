require 'rss/maker'

module Wiki::Helper
  alias include_block_without_changelog include_block

  def include_block(name)
    content = include_block_without_changelog(name)
    if name.to_sym == :head && object
      content << "<link rel=\"alternate\" href=\"#{(object.path/'changelog.rss').urlpath}\" type=\"application/rss+xml\" title=\"RSS\"/>"
    end
    content
  end
end

class Wiki::App
  get '/changelog.rss', '/:path/changelog.rss' do
    object = Object.find!(@repo, params[:path])
    cache_control :etag => object.latest_commit.sha, :last_modified => object.latest_commit.committer_date

    content_type 'application/rss+xml', :charset => 'utf-8'
    content = RSS::Maker.make('2.0') do |rss|
      rss.channel.title = Config.title
      rss.channel.link = request.scheme + '://' +  (request.host + ':' + request.port.to_s)
      rss.channel.description = Config.title + ' Changelog'
      rss.items.do_sort = true
      object.history.each do |commit|
        i = rss.items.new_item
        i.title = commit.message
        i.link = request.scheme + '://' + (request.host + ':' + request.port.to_s)/object.path/commit.sha
        i.date = commit.committer.date
      end
    end
    content.to_s
  end
end

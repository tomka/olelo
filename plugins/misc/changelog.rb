description 'RSS Changelogs'
require     'rss/maker'

class Olelo::Application
  hook :layout do |name, doc|
    if page
      doc.css('head').first << %{<link rel="alternate" href="/changelog.atom" type="application/atom+xml" title="Sitewide Atom Changelog"/>
                                  <link rel="alternate" href="/changelog.rss" type="application/rss+xml" title="Sitewide RSS Changelog"/>}.unindent
      doc.css('head').first << %{<link rel="alternate" href="#{escape_html(absolute_path(page.path/'changelog.atom'))}" type="application/atom+xml"
                                  title="#{escape_html page.path} Atom Changelog"/>
                                  <link rel="alternate" href="#{escape_html(absolute_path(page.path/'changelog.rss'))}" type="application/rss+xml"
                                  title="#{escape_html page.path} RSS Changelog"/>}.unindent if !page.root?
    end
  end

  get '(/:path)/changelog.:format', :format => /rss|atom/  do
    page = Page.find!(params[:path])
    cache_control :etag => page.version, :last_modified => page.version.date

    response['Content-Type'] = "application/#{params[:format]}+xml; charset=utf-8"
    prefix = request.scheme + '://' +  request.host + ':' + request.port.to_s + '/'

    content = RSS::Maker.make(params[:format] == 'rss' ? '2.0' : 'atom') do |feed|
      feed.channel.generator = 'Ōlelo'
      feed.channel.title = Config.title
      feed.channel.link = prefix + page.path
      feed.channel.description = Config.title + ' Changelog'
      feed.channel.id = prefix + page.path
      feed.channel.updated = Time.now
      feed.channel.author = Config.title
      feed.items.do_sort = true
      page.history.each do |version|
        i = feed.items.new_item
        i.title = version.comment
        i.link = prefix + 'changes'/version
        i.date = version.date
        i.dc_creator = version.author.name
      end
    end
    content.to_s
  end
end

author      'Daniel Mendler'
description 'Blog engine'
dependencies 'filter/tag'

class Wiki::Application
  assets 'blog.css'
  patterns :year => '20\d{2}', :month => '(?:0[1-9])|(?:1[1-2])'

  hook :layout do |name, doc|
    if @engine && @engine.name == 'blog'
      doc.css('head').first << '<link rel="stylesheet" href="/_/engine/blog/blog.css" type="text/css"/>'
    end
  end

  get '/:path/?:year', '/:path/?:year/:month' do
    params[:output] = 'blog'
    send('GET /:path')
  end
end

Tag.define('blog-menu') do |context, attrs, content|
  path = attrs[:path].to_s
  tree = Tree.find!(path, context.page.current? ? nil : context.page.tree_version)
  years = {}
  tree.children.each do |child|
    (years[child.version.date.year] ||= [])[child.version.date.month] = true if child.page?
  end
  builder do
    div(:class => 'blog-menu') do
      years.keys.sort.each do |year|
        div(:class => 'year') do
          a.year(:href => resource_path(tree, :path => tree.path/year)) do
            text year
          end
          (1..12).each do |month|
            m = '%02d' % month
            a.month(:href => resource_path(tree, :path => tree.path/year/m)) do
              text m
            end if years[year][month]
          end
        end
      end
    end
  end
end

Engine.create(:blog, :priority => 3, :layout => true, :cacheable => true, :hidden => true) do
  def accepts?(resource); resource.tree?; end
  def output(context)
    @tree = context.tree

    articles = @tree.children.select {|child| child.page? }.sort_by {|child| -child.version.date.to_i }

    year = context.params[:year].to_i
    articles.reject! {|article| article.version.date.year != year } if year != 0
    month = context.params[:month].to_i
    articles.reject! {|article| article.version.date.month != month } if month != 0

    @curpage = context.params[:curpage].to_i
    per_page = 10
    @pages = articles.size / per_page
    articles = articles[(@curpage * per_page) ... ((@curpage + 1) * per_page)].to_a

    @articles = articles.map do |page|
      engine = Engine.find(page, :layout => true)
      if engine
        content = engine.output(context.subcontext(:engine => engine, :resource => page))
        content = Nokogiri::HTML::DocumentFragment.parse(content).xpath('p').first if !context.params[:full]
      else
        content = %{#{:engine_not_available.t(:page => page.name, :type => "#{page.mime.comment} (#{page.mime})", :engine => nil)}}
      end
      [page, content]
    end
    render :blog, :locals => {:full => context.params[:full]}
  end
end

__END__

@@ blog.haml
.blog
  - @articles.each do |page, content|
    .article
      %h2
        %a.name{:href=>resource_path(page)}&= page.name
      .date= date page.version.date
      .author&= :written_by.t(:author => page.version.author.name)
      - tags = page.metadata['tags'].to_a
      - if !tags.empty?
        %ul.tags
          = list_of(tags) do |tag|
            = tag
      .content= content
      - if !full
        %a.full{:href=>resource_path(page)}&= :full_article.t
= pagination(@tree, @pages, @curpage, :output => 'blog')

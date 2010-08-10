description  'Blog engine'
dependencies 'filter/tag', 'utils/asset_manager'

AssetManager.register_scripts '*.css'

class Olelo::Application
  get '/:path/?:year', '/:path/?:year/:month', :year => '20\d{2}', :month => '(?:0[1-9])|(?:1[1-2])' do
    params[:output] = 'blog'
    send('GET /:path')
  end

  hook :layout, 999 do |name, doc|
    doc.css('blog-menu').each do |element|
      menu = Cache.cache("blog-menu-#{element['path']}-#{element['version']}") do
        tree = Tree.find(element['path'], element['version'])
        if tree
          years = {}
          tree.children.each do |child|
            (years[child.version.date.year] ||= [])[child.version.date.month] = true if child.page?
          end
          render :menu, :locals => {:years => years, :tree => tree}, :layout => false
        end
      end
      element.replace menu
    end
  end
end

Tag.define('blog-menu', :description => 'Show blog menu') do |context, attrs, content|
  %{<blog-menu path="#{escape_html attrs['path']}"/>}
end

Engine.create(:blog, :priority => 3, :layout => true, :cacheable => true, :hidden => true, :accepts => Tree::MIME) do
  def output(context)
    @tree = context.tree

    articles = @tree.children.select {|child| child.page? }.sort_by {|child| -child.version.date.to_i }

    year = context.params[:year].to_i
    articles.reject! {|article| article.version.date.year != year } if year != 0
    month = context.params[:month].to_i
    articles.reject! {|article| article.version.date.month != month } if month != 0

    @page = context.params[:page].to_i
    per_page = 10
    @last_page = articles.size / per_page
    articles = articles[(@page * per_page) ... ((@page + 1) * per_page)].to_a

    @articles = articles.map do |page|
      engine = Engine.find(page, :layout => true)
      if engine
        content = engine.output(context.subcontext(:engine => engine, :resource => page))
        if !context.params[:full]
          paragraphs = Nokogiri::XML::DocumentFragment.parse(content).xpath('p')
          content = ''
          paragraphs.each do |p|
            content += p.to_xhtml(:encoding => 'UTF-8')
            break if content.length > 10000
          end
        end
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
        %a.name{:href=>page.path.urlpath}&= page.name
      .date= date page.version.date
      .author&= :written_by.t(:author => page.version.author.name)
      - tags = page.metadata['tags'].to_a
      - if !tags.empty?
        %ul.tags
          = list_of(tags) do |tag|
            = tag
      .content= content
      - if !full
        %a.full{:href=>page.path.urlpath}&= :full_article.t
= pagination(@tree, @last_page, @page, :output => 'blog')
@@ menu.haml
%table.blog-menu
  - years.keys.sort.each do |year|
    %tr
      %td
        %a{:href => (tree.path/year).urlpath}= year
      %td
        - (1..12).select {|m| years[year][m] }.each do |month|
          - m = '%02d' % month
          %a{:href => (tree.path/year/m).urlpath}= m

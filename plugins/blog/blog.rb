description  'Blog engine'
dependencies 'filter/tag', 'utils/asset_manager'

AssetManager.register_scripts '*.css'

class Olelo::Application
  attribute_editor do
    attribute :tags, :stringlist
  end

  get '(/:path)/:year(/:month)', :year => '20\d{2}', :month => '(?:0[1-9])|(?:1[1-2])' do
    params[:output] = 'blog'
    send('GET /')
  end

  hook :layout, 999 do |name, doc|
    doc.css('blog-menu').each do |element|
      menu = Cache.cache("blog-menu-#{element['path']}-#{element['version']}", :update => request.no_cache?, :defer => true) do
        page = Page.find(element['path'], element['version'])
        if page
          years = {}
          page.children.each do |child|
            (years[child.version.date.year] ||= [])[child.version.date.month] = true
          end
          render :menu, :locals => {:years => years, :page => page}, :layout => false
        end
      end
      element.replace menu
    end
  end
end

Tag.define 'blog-menu', :description => 'Show blog menu' do |context, attrs, content|
  %{<blog-menu path="#{escape_html attrs['path']}" version="#{context.page.tree_version}"/>}
end

Engine.create(:blog, :priority => 3, :layout => true, :cacheable => true, :hidden => true) do
  def accepts?(page); !page.children.empty?; end
  def output(context)
    @page = context.page

    articles = @page.children.sort_by {|child| -child.version.date.to_i }

    year = context.params[:year].to_i
    articles.reject! {|article| article.version.date.year != year } if year != 0
    month = context.params[:month].to_i
    articles.reject! {|article| article.version.date.month != month } if month != 0

    @page_nr = context.params[:page].to_i
    per_page = 10
    @last_page = articles.size / per_page
    articles = articles[(@page_nr * per_page) ... ((@page_nr + 1) * per_page)].to_a

    @articles = articles.map do |page|
      engine = Engine.find(page, :layout => true)
      if engine
        content = engine.output(context.subcontext(:engine => engine, :page => page))
        if !context.params[:full]
          paragraphs = Nokogiri::XML::DocumentFragment.parse(content).xpath('p')
          content = ''
          paragraphs.each do |p|
            content += p.to_xhtml(:encoding => 'UTF-8')
            break if content.length > 10000
          end
        end
      else
        content = %{#{:engine_not_available.t(:page => page.title, :type => "#{page.mime.comment} (#{page.mime})", :engine => nil)}}
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
        %a.name{:href => absolute_path(page) }&= page.name
      .date= date page.version.date
      .author&= :written_by.t(:author => page.version.author.name)
      - tags = page.attributes['tags'].to_a
      - if !tags.empty?
        %ul.tags
          = list_of(tags) do |tag|
            = tag
      .content= content
      - if !full
        %a.full{:href => absolute_path(page.path) }&= :full_article.t
= pagination(page_path(@page), @last_page, @page_nr, :output => 'blog')
@@ menu.haml
%table.blog-menu
  - years.keys.sort.each do |year|
    %tr
      %td
        %a{:href => absolute_path(page.path/year) }= year
      %td
        - (1..12).select {|m| years[year][m] }.each do |month|
          - m = '%02d' % month
          %a{:href => absolute_path(page.path/year/m) }= m

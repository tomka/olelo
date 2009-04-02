Wiki::Plugin.define 'tag/include' do
  depends_on 'filter/tag'

  Wiki::Tag.define(:include, :requires => :page) do |page,attrs,content|
    if page = Wiki::Page.find(page.repo, attrs['page'])
      engine = Wiki::Engine.find(page)
      if engine.layout?
        engine.render(page)
      else
        "<span class=\"error\">No engine found for #{attrs['page']}</span>"
      end
    else
      "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
    end
  end
end

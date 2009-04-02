Wiki::Plugin.define 'tag/include' do
  depends_on 'filter/tag'

  Wiki::Tag.define(:param, :requires => :key) do |page, params, attrs, content|
    escape_html(params[attrs['key']])
  end

  Wiki::Tag.define(:include, :requires => :page) do |page, params, attrs, content|
    if page = Wiki::Page.find(page.repo, attrs['page'])
      engine = Wiki::Engine.find(page, attrs['output'])
      if engine && engine.layout?
        engine.render(page, attrs)
      else
        "<span class=\"error\">No engine found for #{attrs['page']}</span>"
      end
    else
      "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
    end
  end
end

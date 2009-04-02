Wiki::Plugin.define 'tag/include' do
  depends_on 'filter/tag'

  Wiki::Tag.define(:param, :requires => :key) do |context, attrs, content|
    escape_html(context[attrs['key']])
  end

  Wiki::Tag.define(:include, :requires => :page) do |context, attrs, content|
    context['__includelevel__'] ||= 0
    context['__includelevel__'] += 1
    return 'Maximum include level exceeded' if context['__includelevel__'] > 10

    if page = Wiki::Page.find(context.page.repo, attrs['page'])
      engine = Wiki::Engine.find(page, attrs['output'])
      if engine && engine.layout?
        engine.output(context.subcontext(engine, page, attrs))
      else
        "<span class=\"error\">No engine found for #{attrs['page']}</span>"
      end
    else
      "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
    end
  end
end

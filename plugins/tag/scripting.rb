Wiki::Plugin.define 'tag/scripting' do
  depends_on 'filter/tag'
  require 'expr'

  Wiki::Tag.define(:param, :requires => :name) do |context, attrs, content|
    escape_html(context[attrs['name']])
  end

  Wiki::Tag.define(:echo, :requires => :select) do |context, attrs, content|
    escape_html(Expr.eval(attrs['select'], context))
  end

  Wiki::Tag.define(:set, :requires => [:name, :select]) do |context, attrs, content|
    context[attrs['name']] = Expr.eval(attrs['select'], context)
    ''
  end

  Wiki::Tag.define(:include, :requires => :page) do |context, attrs, content|
    if page = Wiki::Page.find(context.page.repo, attrs['page'])
      engine = Wiki::Engine.find(page, attrs['output']) rescue nil
      if engine && engine.layout?
        engine.output(context.subcontext(attrs.merge(:engine => engine, :page => page)))
      else
        "<span class=\"error\">No engine found for #{attrs['page']}</span>"
      end
    else
      "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
    end
  end

  Wiki::Tag.define(:repeat, :requires => :times) do |context, attrs, content|
    n = [10, attrs['times'].to_i].max
    (1..n).map do |i|
      sub = context.subcontext(attrs['counter'] ? {attrs['counter'] => i} : {})
      call(sub, content.dup)
    end.join
  end

  Wiki::Tag.define(:if, :requires => :test) do |context, attrs, content|
    if Expr.eval(attrs['test'], context)
      call(context.subcontext, content)
    end
  end
end

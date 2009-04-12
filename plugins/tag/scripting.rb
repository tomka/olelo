Wiki::Plugin.define 'tag/scripting' do
  depends_on 'filter/tag'
  require 'expr'

  Wiki::Tag.define(:param, :requires => :name, :immediate => true) do |context, attrs, content|
    escape_html(context[attrs['name']])
  end

  Wiki::Tag.define(:echo, :requires => :select, :immediate => true) do |context, attrs, content|
    escape_html(Expr.eval(attrs['select'], context))
  end

  Wiki::Tag.define(:set, :requires => [:name, :select], :immediate => true) do |context, attrs, content|
    context[attrs['name']] = Expr.eval(attrs['select'], context)
    ''
  end

  Wiki::Tag.define(:include, :requires => :page) do |context, attrs, content|
    if page = Wiki::Page.find(context.page.repo, attrs['page'])
      engine = Wiki::Engine.find(page, attrs['output'])
      if engine && engine.layout?
        engine.output(context.subcontext(attrs.merge(:engine => engine, :page => page)))
      else
        "include: No engine found for #{attrs['page']}"
      end
    else
      "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
    end
  end

  Wiki::Tag.define(:repeat, :requires => :times, :immediate => true) do |context, attrs, content|
    n = [10, attrs['times'].to_i].max
    (1..n).map do |i|
      params = attrs['counter'] ? {attrs['counter'] => i} : {}
      nested_tags(context.subcontext(params), content.dup)
    end.join
  end

  Wiki::Tag.define(:if, :requires => :test, :immediate => true) do |context, attrs, content|
    if Expr.eval(attrs['test'], context)
      nested_tags(context.subcontext, content)
    end
  end
end

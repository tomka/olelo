Wiki::Plugin.define 'tag/scripting' do
  depends_on 'filter/tag'
  require 'expr'

  Wiki::Tag.define(:param, :requires => :name, :immediate => true) do |context, attrs, content|
    escape_html(context[attrs['name']])
  end

  Wiki::Tag.define(:echo, :requires => :value, :immediate => true) do |context, attrs, content|
    escape_html(Expr.eval(attrs['value'], context))
  end

  Wiki::Tag.define(:set, :requires => [:name, :value], :immediate => true) do |context, attrs, content|
    context[attrs['name']] = Expr.eval(attrs['value'], context)
    ''
  end

  Wiki::Tag.define(:include, :requires => :page) do |context, attrs, content|
    if page = Wiki::Page.find(context.page.repo, attrs['page'])
      engine = Wiki::Engine.find(page, attrs['output'])
      raise(Exception, "No engine found for #{attrs['page']}") if !engine || engine.layout?
      engine.output(context.subcontext(attrs.merge(:engine => engine, :page => page)))
    else
      "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
    end
  end

  Wiki::Tag.define(:for, :requires => [:from, :to], :immediate => true) do |context, attrs, content|
    to = attrs['to'].to_i
    from = attrs['from'].to_i
    raise(Exception, "Limits exceeded") if to - from > 10
    (from..to).map do |i|
      params = attrs['counter'] ? {attrs['counter'] => i} : {}
      nested_tags(context.subcontext(params), content.dup)
    end.join
  end

  Wiki::Tag.define(:repeat, :requires => :times, :immediate => true) do |context, attrs, content|
    n = [10, attrs['times'].to_i].min
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

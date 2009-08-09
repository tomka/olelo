dependencies 'filter/tag'
require      'evaluator'
author       'Daniel Mendler'
description  'Scripting tags'

class Wiki::Engine::Context
  def function_table
    self['__FUNCTION_TABLE__'] ||= {}
  end
end

Tag.define(:value, :requires => :of, :immediate => true) do |context, attrs, content|
  escape_html(Evaluator(attrs['of'], context))
end

Tag.define(:calc) do |context, attrs, content|
  code = content.strip.split("\n").map do |line|
    line.strip!
    val = if line =~ /^(\w+)\s*:=?\s*(.*)$/
      context[$1] = Evaluator($2, context)
    else
      Evaluator(line, context)
    end
    "> #{line}\n#{val}\n"
  end.join
  "<pre>#{escape_html code}</pre>"
end

Tag.define(:def, :requires => :name, :immediate => true) do |context, attrs, content|
  name = attrs['name'].downcase
  if attrs['value']
    context[name] = Evaluator(attrs['value'], context)
  else
    context.function_table[name] = [attrs['args'].to_s.split(/\s+/), content]
  end
  nil
end

Tag.define(:call, :requires => :name, :immediate => true) do |context, attrs, content|
  name = attrs['name'].downcase
  raise(NameError, "Function #{name} not found") if !context.function_table[name]
  args, content = context.function_table[name]
  args = args.map do |arg|
    raise(NameError, "Argument #{arg} is required") if !attrs[arg]
    [arg, Evaluator(attrs[arg], context)]
  end.flatten
  result = nested_tags(context.subcontext(Hash[*args]), content)
  if attrs['result']
    context[attrs['result']] = result
    nil
  else
    result
  end
end

Tag.define(:include, :requires => :page, :limit => 5) do |context, attrs, content|
  if page = Page.find(context.page.repo, attrs['page'])
    engine = Engine.find(page, attrs['output'])
    raise(RuntimeError, "No engine found for #{attrs['page']}") if !engine || !engine.layout?
    engine.output(context.subcontext(attrs.merge(:engine => engine, :page => page)))
  else
    "<a href=\"/#{attrs['page']}/new\">Create #{attrs['page']}</a>"
  end
end

Tag.define(:for, :requires => [:from, :to], :immediate => true, :limit => 50) do |context, attrs, content|
  to = attrs['to'].to_i
  from = attrs['from'].to_i
  raise(RuntimeError, "Limits exceeded") if to - from > 10
  (from..to).map do |i|
    params = attrs['counter'] ? {attrs['counter'] => i} : {}
    nested_tags(context.subcontext(params), content)
  end.join
end

Tag.define(:repeat, :requires => :times, :immediate => true, :limit => 50) do |context, attrs, content|
  n = attrs['times'].to_i
  raise(RuntimeError, "Limits exceeded") if n > 10
  (1..n).map do |i|
    params = attrs['counter'] ? {attrs['counter'] => i} : {}
    nested_tags(context.subcontext(params), content)
  end.join
end

Tag.define(:if, :requires => :test, :immediate => true) do |context, attrs, content|
  if Evaluator(attrs['test'], context)
    nested_tags(context.subcontext, content)
  end
end

Tag.define(:quiet, :immediate => true) do |context, attrs, content|
  doc = Hpricot.XML(content)
  doc.traverse_text { |elem| elem.content = '' }
  nested_tags(context.subcontext, doc.to_original_html)
end

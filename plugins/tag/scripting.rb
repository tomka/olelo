author       'Daniel Mendler'
description  'Scripting tags'
dependencies 'filter/tag', 'gem:evaluator'
autoload 'Evaluator', 'evaluator'

# Add standard variables
Wiki::Engine::Context.hook(:initialized) do
  params['page_name'] = page.name
  params['page_path'] = page.path
  params['page_title'] = page.title
  params['page_version'] = page.commit ? page.commit.sha : ''
  params['is_current'] = page.current?
  params['is_discussion'] = page.discussion?
  params['is_meta'] = page.meta?
end

Tag.define(:value, :requires => :of, :immediate => true) do |context, attrs, content|
  Evaluator.eval(attrs['of'], context.params)
end

Tag.define(:calc) do |context, attrs, content|
  code = content.strip.split("\n").map do |line|
    line.strip!
    val = if line =~ /^(\w+)\s*:=?\s*(.*)$/
      context.params[$1] = Evaluator.eval($2, context.params)
    else
      Evaluator.eval(line, context.params)
    end
    "> #{line}\n#{val}\n"
  end.join
  "<pre>#{Wiki.html_escape code}</pre>"
end

Tag.define(:def, :requires => :name, :immediate => true) do |context, attrs, content|
  name = attrs['name'].downcase
  if attrs['value']
    context.params[name] = Evaluator.eval(attrs['value'], context.params)
  else
    functions = context.private[:functions] ||= {}
    functions[name] = [attrs['args'].to_s.split(/\s+/), content]
  end
  nil
end

Tag.define(:call, :requires => :name, :immediate => true) do |context, attrs, content|
  name = attrs['name'].downcase
  functions = context.private[:functions]
  raise NameError, "Function #{name} not found" if !functions || !functions[name]
  args, content = functions[name]
  args = args.map do |arg|
    raise ArgumentError, "Argument #{arg} is required" if !attrs[arg]
    [arg, Evaluator.eval(attrs[arg], context.params)]
  end.flatten
  result = nested_tags(context.subcontext(:params => Hash[*args]), content)
  if attrs['result']
    context.params[attrs['result']] = result
    nil
  else
    result
  end
end

Tag.define(:include, :requires => :page, :limit => 10) do |context, attrs, content|
  path = attrs['page']
  if !path.begins_with? '/'
    path = context.resource.page? ? context.resource.path/'..'/path : context.resource.path/path
  end
  if page = Page.find(context.resource.repository, path)
    engine = Engine.find(page, :name => attrs['output'] || attrs['engine'], :layout => true)
    raise NameError, "No engine found for #{path}" if !engine
    engine.output(context.subcontext(:app => context.app, :params => attrs,
                                     :engine => engine, :resource => page, :private => {:included => true}))
  else
    %{<a href="/#{Wiki.html_escape path}/new">Create #{Wiki.html_escape path}</a>}
  end
end

Tag.define(:includeonly, :immediate => true) do |context, attrs, content|
  nested_tags(context, content) if context.private[:included]
end

Tag.define(:noinclude, :immediate => true) do |context, attrs, content|
  nested_tags(context, content) if !context.private[:included]
end

Tag.define(:for, :requires => [:from, :to], :immediate => true, :limit => 50) do |context, attrs, content|
  to = attrs['to'].to_i
  from = attrs['from'].to_i
  raise RuntimeError, 'Limits exceeded' if to - from > 10
  (from..to).map do |i|
    params = attrs['counter'] ? {attrs['counter'] => i} : {}
    nested_tags(context.subcontext(:params => params), content)
  end.join
end

Tag.define(:repeat, :requires => :times, :immediate => true, :limit => 50) do |context, attrs, content|
  n = attrs['times'].to_i
  raise RuntimeError, 'Limits exceeded' if n > 10
  (1..n).map do |i|
    params = attrs['counter'] ? {attrs['counter'] => i} : {}
    nested_tags(context.subcontext(:params => params), content)
  end.join
end

Tag.define(:if, :requires => :test, :immediate => true) do |context, attrs, content|
  if Evaluator.eval(attrs['test'], context.params)
    nested_tags(context.subcontext, content)
  end
end

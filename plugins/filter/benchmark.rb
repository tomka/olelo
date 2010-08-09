description  'Filter engine benchmark'
dependencies 'engine/filter'

class Olelo::Filter
  redefine_method :subfilter do |context, content|
    @timer.measure_not { super(context, content) }
  end

  def call!(context, content)
    timers = (context.private[:timers] ||= {})
    match = Filter.registry.find {|name, klass| klass == self.class }
    @timer = timers[match ? match[0] : self.class.name] ||= Timer.new
    content = @timer.measure { filter(context, content) }
    post ? post.call(context, content) : content
  end
end

class Olelo::FilterEngine
  redefine_method :output do |context|
    timer = Timer.new
    result = timer.measure { super(context) }
    context.logger.info "Benchmark of engine #{name} on #{context.resource.path} - #{timer.elapsed_ms}ms"
    timers = context.private[:timers] || {}
    timers.each {|name, timer| context.logger.info "#{name}: #{timer.elapsed_ms}ms" }
    result
  end
end

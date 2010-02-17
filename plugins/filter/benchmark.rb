author      'Daniel Mendler'
description 'Filter engine benchmark'
dependencies 'engine/filter'

class Wiki::Filter
  redefine_method :subfilter do |content|
    @timer.measure_not { super(content) }
  end

  def call!(content)
    @timer = context.engine.timers[name] ||= Timer.new
    content = @timer.measure { filter(content) }
    post ? post.call(context, content) : content
  end
end

class Wiki::FilterEngine
  redefine_method :output do |context|
    timer = Timer.new
    result = timer.measure { super(context) }
    context.logger.info "Benchmark of engine #{name} on #{context.resource.path} - #{timer.elapsed_ms}ms"
    timers.each {|name, timer| context.logger.info "#{name}: #{timer.elapsed_ms}ms" }
    result
  end

  def timers
    @timers ||= {}
  end
end

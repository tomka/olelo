author      'Daniel Mendler'
description 'Filter engine benchmark'
dependencies 'engine/filter'

class Wiki::Filter
  redefine_method :subfilter do |content|
    start = Time.now
    result = super(content)
    @runtime += start - Time.now
    result
  end

  def call!(content)
    @runtime = 0
    start = Time.now
    content = filter(content)
    @runtime += Time.now - start
    context.engine.runtimes[name] ||= 0
    context.engine.runtimes[name] += @runtime
    post ? post.call(context, content) : content
  end
end

class Wiki::FilterEngine
  redefine_method :output do |context|
    start = Time.now
    result = super(context)
    context.logger.info "Benchmark of #{name} on #{context.resource.path} - #{((Time.now - start) * 1000).to_i}ms"
    runtimes.each do |name, runtime|
      context.logger.info "#{name}: #{(runtime * 1000).to_i}ms"
    end
    result
  end

  def runtimes
    @runtimes ||= {}
  end
end

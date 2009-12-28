author      'Daniel Mendler'
description 'Filter engine benchmark'
dependencies 'engine/filter'

class Wiki::Filter
  def subfilter(content)
    start = Time.now
    result = sub ? sub.call(context, content) : content
    @runtime -= Time.now - start
    result
  end

  def call!(content)
    start = Time.now
    @runtime = 0
    content = filter(content)
    @runtime += Time.now - start
    context.engine.runtimes[name] ||= 0
    context.engine.runtimes[name] += @runtime
    post ? post.call(context, content) : content
  end
end

class Wiki::FilterEngine
  alias original_output output

  def output(context)
    result = original_output(context)
    context.logger.info "Benchmark of #{name}"
    @runtimes.each do |name, runtime|
      context.logger.info "#{name}: #{(runtime * 1000).to_i}ms"
    end
    result
  end

  def runtimes
    @runtimes ||= {}
  end
end

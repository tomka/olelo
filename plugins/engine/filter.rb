author      'Daniel Mendler'
description 'Filter pipeline engine'

class Wiki::Filter
  include Helper
  include Templates

  @filters = {}

  attr_reader :name
  attr_accessor :context, :sub, :post

  def initialize(name)
    @name = name.to_s
    @context = nil
    @sub = nil
    @post = nil
  end

  def subfilter(content)
    sub ? sub.call(context, content) : content
  end

  def call(context, content)
    f = dup
    f.context = context
    f.call!(content)
  end

  def call!(content)
    content = filter(content)
    post ? post.call(context, content) : content
  end

  def self.register(filter)
    raise(ArgumentError, "Filter #{filter.name} already exists") if @filters.key?(filter.name)
    @filters[filter.name] = filter
  end

  def self.create(name, &block)
    filter = Class.new(Filter)
    filter.class_eval { define_method(:filter, &block) }
    register filter.new(name)
  end

  def self.get(name)
    name = name.to_s
    Plugin.load("filter/#{name}")
    @filters.include?(name) && @filters[name].dup
  end

  class Builder
    def initialize(logger)
      @logger = logger
      @filter = @last_filter = nil
    end

    def filter(*filters, &block)
      filters.each do |name|
        filter = Filter.get(name)
        if filter
          if @last_filter
            @last_filter.post = filter
            @last_filter = @last_filter.post
          else
            @last_filter = @filter = filter
          end
        else
          @logger.warn "Filter #{name} not available"
        end
      end
      if block
        filter = Filter::Builder.new(@logger).build(&block)
        if @last_filter
          @last_filter.sub = filter
        else
          @last_filter = @filter = filter
        end
      end
    end

    def build(&block)
      instance_eval(&block)
      @filter
    end
  end
end

class FilterEngine < Engine
  def initialize(name, config, filter)
    super(name, config)
    @accepts = config[:accepts]
    @mime = config[:mime]
    @filter = filter
  end

  def accepts?(page)
    page.mime.to_s =~ /^#{@accepts}$/
  end

  def mime(page)
    @mime || page.mime
  end

  def output(context)
    @filter.call(context, context.page.content)
  end

  class Builder < Filter::Builder
    def initialize(name, logger)
      super(logger)
      @name = name
      @config = {}
    end

    def build(&block)
      instance_eval(&block)
      raise(RuntimeError, "No filters defined for engine #{name}") if !@filter
      FilterEngine.new(@name, @config, @filter)
    end

    def mime(mime);         @config[:mime] = mime;       end
    def accepts(accepts);   @config[:accepts] = accepts; end
    def needs_layout;       @config[:layout] = true;     end
    def has_priority(prio); @config[:priority] = prio;   end
    def is_cacheable;       @config[:cacheable] = true;  end
  end

  class Registrator
    def initialize(logger)
      @logger = logger
    end

    def engine(name, &block)
      Engine.register(Builder.new(name, @logger).build(&block))
      @logger.info "Filter engine #{name} successfully created"
    rescue Exception => ex
      @logger.error ex
    end
  end
end


setup do
  file = File.join(Config.root, 'engines.rb')
  FilterEngine::Registrator.new(logger).instance_eval(File.read(file), file)
end

description 'Filter pipeline engine'
dependencies 'engine/engine'

class Olelo::Filter
  include PageHelper
  include Templates
  extend Factory

  attr_reader :options
  attr_accessor :context, :sub, :post

  class MandatoryFilterNotFound < NameError; end

  def initialize(options)
    @context = nil
    @sub = nil
    @post = nil
    @options = options
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

  def self.create(name, &block)
    filter = Class.new(Filter)
    filter.class_eval { define_method(:filter, &block) }
    register(name, filter)
  end

  class Builder
    def initialize(name)
      @name = name
      @filter = []
    end

    # Add optional filter
    def filter(name, options = nil, &block)
      add(name, false, options, &block)
    end

    # Add mandatory filter
    def filter!(name, options = nil, &block)
      add(name, true, options, &block)
    end

    # Add filter with method name.
    # Mandatory filters must end with !
    def method_missing(name, options = nil, &block)
      name = name.to_s
      name.ends_with?('!') ? filter!(name[0..-2], options, &block) : filter(name, options, &block)
    end

    def build(&block)
      instance_eval(&block)
      @filter.first
    end

    private

    def add(name, mandatory, options = nil, &block)
      filter = Filter[name] rescue nil
      if filter
        filter = filter.new((options || {}).with_indifferent_access)
        @filter.last.post = filter if @filter.last
        @filter << filter
        filter.sub = Filter::Builder.new(@name).build(&block) if block
      else
        if mandatory
          raise MandatoryFilterNotFound, "Engine '#{@name}' not created because mandatory filter '#{name}' is not available"
        else
          Plugin.current.logger.warn "Optional filter '#{name}' not available"
        end
        @filter << Filter::Builder.new(@name).build(&block) if block
      end
      self
    end
  end
end

class Olelo::FilterEngine < Engine
  def initialize(name, options, filter)
    super(name, options)
    @accepts = options[:accepts]
    @mime = options[:mime]
    @filter = filter
  end

  def accepts?(page)
    page.mime.to_s =~ /^#{@accepts}$/
  end

  def mime(page)
    @mime || page.mime
  end

  def output(context)
    @filter.call(context, context.page.content.dup)
  end

  class Builder
    def initialize(name)
      @name = name
      @options = {}
    end

    def build(&block)
      instance_eval(&block)
      raise("No filters defined for engine '#{name}'") if !@filter
      FilterEngine.new(@name, @options, @filter)
    end

    def filter(&block)
      @filter = Filter::Builder.new(@name).build(&block)
      self
    end

    def mime(mime);         @options[:mime] = mime;       self; end
    def accepts(accepts);   @options[:accepts] = accepts; self; end
    def needs_layout;       @options[:layout] = true;     self; end
    def has_priority(prio); @options[:priority] = prio;   self; end
    def is_cacheable;       @options[:cacheable] = true;  self; end
  end

  class Registrator
    def engine(name, &block)
      Engine.register(Builder.new(name).build(&block))
      Plugin.current.logger.debug "Filter engine '#{name}' successfully created"
    rescue Filter::MandatoryFilterNotFound => ex
      Plugin.current.logger.warn ex.message
    rescue Exception => ex
      Plugin.current.logger.error ex
    end
  end
end

def setup
  file = File.join(Config.config_path, 'engines.rb')
  FilterEngine::Registrator.new.instance_eval(File.read(file), file)
end

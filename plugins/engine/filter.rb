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

  def self.find(name)
    Plugin.load("filter/#{name}")
    name = name.to_s
    raise(NameError, "Filter #{name} not found") if !@filters.include?(name)
    @filters[name].dup
  end
end

class FilterEngine <  Engine
  def initialize(name, config)
    config = config.with_indifferent_access
    super(name, config)
    @accepts = config[:accepts]
    @mime = config[:mime]
    @filter = build(config[:filter])
  end

  def build(list)
    if Array === list
      filter = Filter.find(list.shift)
      list.inject(filter) do |f,name|
        if Array === name
          f.sub = build(name)
          f
        else
          f.post = Filter.find(name)
        end
      end
      filter
    else
      Filter.find(list)
    end
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
end

setup do
  engines = YAML.load_file(File.join(Config.root, 'engines.yml'))
  engines.each_pair do |name, config|
    begin
      Engine.register(FilterEngine.new(name, config))
    rescue Exception => ex
      logger.error ex
    end
  end
end

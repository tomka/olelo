Wiki::Plugin.define 'engine/filter' do
  class Wiki::Filter
    @filters = {}

    class NotFound < ArgumentError
      def initialize(name)
        super("Filter #{name} not found")
      end
    end

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
      raise ArgumentError, "Filter #{filter.name} already exists" if @filters.key?(filter.name)
      @filters[filter.name] = filter
    end

    def self.create(name, &block)
      filter = Class.new(Wiki::Filter)
      filter.class_eval { define_method(:filter, &block) }
      register filter.new(name)
    end

    def self.find(name)
      Wiki::Plugin.load("filter/#{name}")
      name = name.to_s
      raise NotFound, name if !@filters.include?(name)
      @filters[name].dup
    end
  end

  class Wiki::FilterEngine <  Wiki::Engine
    def initialize(name, config)
      super(name, !!config['layout'], !!config['cacheable'], (config['priority'] || 99).to_i)
      @accepts = config['accepts']
      @mime = config['mime']
      @filter = build(config['filter'])
    end

    def build(list)
      if Array === list
        filter = Wiki::Filter.find(list.shift)
        list.inject(filter) do |f,name|
          if Array === name
            f.sub = build(name)
            f
          else
            f.post = Wiki::Filter.find(name)
          end
        end
        filter
      else
        Wiki::Filter.find(list)
      end
    end

    accepts do |page|
      page.mime.to_s =~ /^#{@accepts}$/
    end

    mime do |page|
      @mime || page.mime
    end

    output do |context|
      @filter.call(context, context.page.content)
    end
  end

  setup do
    engines = YAML.load_file(File.join(Wiki::Config.root, 'engines.yml'))
    engines.each_pair do |name, config|
      begin
        Wiki::Engine.register(Wiki::FilterEngine.new(name, config))
      rescue Exception => ex
        logger.error ex
      end
    end
  end
end

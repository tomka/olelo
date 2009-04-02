Wiki::Plugin.define 'engine/filter' do
  class Wiki::Filter
    @filters = {}

    class NotFound < ArgumentError
      def initialize(name)
        super("Filter #{name} not found")
      end
    end

    attr_reader :name
    attr_accessor :page, :params, :sub, :post

    def initialize(name)
      @name = name.to_s
      @page = nil
      @params = {}
      @sub = nil
      @post = nil
    end

    def after(content)
      content
    end

    def before(content)
      content
    end

    def filter(content)
      sub ? after(sub.call(page, params, before(content))) : after(before(content))
    end

    def call(page, params, content)
      f = dup
      f.page = page
      f.params = params
      f.call!(content)
    end

    def call!(content)
      content = filter(content)
      post ? post.call(page, params, content) : content
    end

    def self.register(filter)
      @filters[filter.name] = filter
    end

    def self.create(name, &block)
      filter = Class.new(Wiki::Filter)
      filter.class_eval { define_method(:filter, &block) }
      register filter.new(name)
    end

    def self.find(name)
      name = name.to_s
      raise NotFound, name if !@filters.include?(name)
      @filters[name].dup
    end
  end

  load 'filter/*'

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
            f.post = Wiki::Filter.find(name.shift)
            f.post.sub = build(name)
            f.post
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

    output do |page, params|
      @filter.call(page, params, page.content)
    end
  end

  engines = YAML.load_file(File.join(Wiki::Config.root, 'engines.yml'))
  engines.each_pair do |name, config|
    begin
      Wiki::Engine.register(Wiki::FilterEngine.new(name, config))
    rescue
    end
  end
end

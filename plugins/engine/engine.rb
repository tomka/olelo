description 'Engine subsystem'
dependencies 'utils/cache'

# Engine context
# A engine context holds the request parameters and other
# variables used by the engines.
# It is possible for a engine to run sub-engines. For this
# purpose you create a subcontext which inherits the variables.
class Olelo::Context
  include Hooks

  attr_reader :page, :parent, :private, :params, :response

  def initialize(attrs = {})
    @page     = attrs[:page]
    @parent   = attrs[:parent]
    @private  = attrs[:private]  || Hash.with_indifferent_access
    @params   = attrs[:params]   || Hash.with_indifferent_access
    @response = attrs[:response] || Hash.with_indifferent_access
    invoke_hook(:initialized)
  end

  def subcontext(attrs = {})
    Context.new(:page    => attrs[:page] || @page,
                :parent  => self,
                :private => @private.merge(attrs[:private] || {}),
                :params  => @params.merge(attrs[:params] || {}),
                :response => @response)
  end
end

# An Engine renders pages
# Engines get a page as input and create text.
class Olelo::Engine
  include PageHelper
  include Templates

  @engines = {}

  # Constructor for engine
  # Options:
  # * layout: Engine output should be wrapped in HTML layout (Not used for download/image engines for example)
  # * priority: Engine priority. The engine with the lowest priority will be used for a page.
  # * cacheable: Engine is cacheable
  def initialize(name, options)
    @name      = name.to_s
    @layout    = !!options[:layout]
    @hidden    = !!options[:hidden]
    @cacheable = !!options[:cacheable]
    @priority  = (options[:priority] || 99).to_i
    @accepts   = options[:accepts]
    @mime      = options[:mime]
  end

  attr_reader :name, :priority, :mime, :accepts
  attr_reader? :layout, :hidden, :cacheable

  # Engines hash
  def self.engines
    @engines
  end

  # Create engine class. This is sugar to create and
  # register an engine class in one step.
  def self.create(name, opts = {}, &block)
    engine = Class.new(Engine)
    engine.class_eval(&block)
    register engine.new(name, opts)
  end

  # Register engine instance
  def self.register(engine)
    (@engines[engine.name] ||= []) << engine
  end

  # Find all accepting engines for a page which are not hidden
  def self.find_all(page)
    name = page.attributes['output']
    @engines.values.map do |engines|
      engines.sort_by {|e| e.priority }.find {|e| (e.name == name || !e.hidden?) && e.accepts?(page) }
    end.compact.sort_by {|e| e.name }
  end

  # Find appropiate engine for page. An optional
  # name can be given to claim a specific engine.
  # If no engine is found a exception is raised.
  def self.find!(page, opts = {})
    opts[:name] ||= page.attributes['output']
    engines = opts[:name] ? @engines[opts[:name].to_s] : @engines.values.flatten
    engine = engines.to_a.sort_by {|e| e.priority }.find { |e| e.accepts?(page) && (!opts[:layout] || e.layout?) }
    raise(:engine_not_available.t(:engine => opts[:name],
                                  :page => page.path,
                                  :type => "#{page.mime.comment} (#{page.mime})")) if !engine
    engine.dup
  end

  # Find appropiate engine for page. An optional
  # name can be given to claim a specific engine.
  # If no engine is found nil is returned.
  def self.find(page, opts = {})
    find!(page, opts) rescue nil
  end

  # Acceptor should return true if page would be accepted by this engine.
  # Reimplement this method.
  def accepts?(page)
    page.mime.to_s =~ /#{@accepts}/
  end

  # Render page content.
  # Reimplement this method.
  def output(context); raise NotImplementedError; end
end

# Plug-in the engine subsystem
class Olelo::Application
  register_attribute(:output) do
    Hash[*Engine.engines.keys.map do |name|
           [name, Olelo::I18n.translate("engine_#{name}", :fallback => name.tr('_', ' ').capitalize)]
         end.flatten]
  end

  before :show do
    @engine_name, layout, response, content =
    Cache.cache("engine-#{page.path}-#{page.version}-#{build_query(params)}",
                :marshal => true, :update => request.no_cache?, :defer => true) do |cache|
      engine = Engine.find!(page, :name => params[:output])
      cache.disable! if !engine.cacheable?
      context = Context.new(:page => page, :params => params)
      content = engine.output(context)
      context.response['Content-Type'] ||= engine.mime.to_s if engine.mime
      context.response['Content-Type'] ||= page.mime.to_s if !engine.layout?
      [engine.name, engine.layout?, context.response.to_hash, content]
    end
    self.response.header.merge!(response)
    if layout
      if request.xhr?
        content = "<h1>#{escape_html page.title}</h1>#{content}"
      else
        content = render(:show, :locals => {:content => content})
      end
    end
    halt content
  end

  hook :layout do |name, doc|
    doc.css('#menu .action-view').each do |link|
      menu = Cache.cache("engine-menu-#{page.path}-#{page.version}-#{build_query(params)}",
                         :update => request.no_cache?, :defer => true) do
        engines = Olelo::Engine.find_all(page)
        li = engines.select {|e| e.layout? }.map do |e|
          name = escape_html Olelo::I18n.translate("engine_#{e.name}", :fallback => e.name.tr('_', ' ').capitalize)
          %{<li#{e.name == @engine_name ? ' class="selected"': ''}>
          <a href="#{escape_html page_path(page, :output => e.name)}">#{name}</a></li>}.unindent
        end +
          engines.select {|e| !e.layout? }.map do |e|
          name = escape_html Olelo::I18n.translate("engine_#{e.name}", :fallback => e.name.tr('_', ' '))
          %{<li class="download#{e.name == @engine_name ? 'selected': ''}">
                <a href="#{escape_html page_path(page, :output => e.name)}">#{name}</a></li>}.unindent
        end
        "<ul>#{li.join}</ul>"
      end
      link.after(menu)
    end
  end
end

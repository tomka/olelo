description 'Engine subsystem'

# Engine context
# A engine context holds the request parameters and other
# variables used by the engines.
# It is possible for a engine to run sub-engines. For this
# purpose you create a subcontext which inherits the variables.
class Olelo::Context < Struct.new(:app, :resource, :engine, :logger, :request,
                                 :response, :parent, :private, :params)
  include Hooks

  alias page resource
  alias tree resource

  def initialize(attrs = {})
    update(attrs)
    self.logger  ||= Logger.new(nil)
    self.params  ||= Hash.with_indifferent_access
    self.private ||= Hash.with_indifferent_access
    invoke_hook(:initialized)
  end

  def subcontext(attrs = {})
    attrs = to_hash.with_indifferent_access.merge!(attrs)
    attrs[:params] = params.merge(attrs[:params] || {})
    attrs[:private] = private.merge(attrs[:private] || {})
    attrs[:parent] = self
    Context.new(attrs)
  end
end

# An Engine renders resources
# Engines get a resource as input and create text.
class Olelo::Engine
  include PageHelper
  include Templates

  @engines = {}

  # Constructor for engine
  # Options:
  # * layout: Engine output should be wrapped in HTML layout (Not used for download/image engines for example)
  # * cacheable: Engine output can be cached
  # * priority: Engine priority. The engine with the lowest priority will be used for a resource.
  def initialize(name, options)
    @name = name.to_s
    @layout = !!options[:layout]
    @cacheable = !!options[:cacheable]
    @hidden = !!options[:hidden]
    @priority = (options[:priority] || 99).to_i
    @accepts = options[:accepts]
    @mime = options[:mime]
    @options = options
  end

  attr_reader :name, :priority, :options
  attr_reader? :layout, :cacheable, :hidden

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

  # Find all accepting engines for a resource which are not hidden
  def self.find_all(resource)
    name = resource.metadata[:output] || resource.metadata[:engine]
    @engines.values.flatten.select do |e|
      ((!resource.namespace.metadata? && e.name == name) || !e.hidden?) && e.accepts?(resource)
    end.sort_by {|a| a.name }
  end

  # Find appropiate engine for resource. An optional
  # name can be given to claim a specific engine.
  # If no engine is found a exception is raised.
  def self.find!(resource, opts = {})
    opts[:name] ||= resource.metadata[:output] || resource.metadata[:engine] if !resource.namespace.metadata?
    engines = opts[:name] ? @engines[opts[:name].to_s] : @engines.values.flatten
    engine = engines.to_a.sort_by {|a| a.priority }.find { |e| e.accepts?(resource) && (!opts[:layout] || e.layout?) }
    raise(:engine_not_available.t(:engine => opts[:name],
                                  :page => resource.path,
                                  :type => "#{resource.mime.comment} (#{resource.mime})")) if !engine
    engine.dup
  end

  # Find appropiate engine for resource. An optional
  # name can be given to claim a specific engine.
  # If no engine is found nil is returned.
  def self.find(resource, opts = {})
    find!(resource, opts) rescue nil
  end

  # Acceptor should return true if resource would be accepted by this engine.
  # Reimplement this method.
  def accepts?(resource)
    resource.mime.to_s =~ /#{@accepts}/
  end

  # Render resource content.
  # Reimplement this method.
  def output(context); context.resource.content; end

  # Get output mime type.
  # Reimplement this method.
  def mime(resource); @mime || resource.mime; end

  # Render resource with possible caching. It should not be overwritten.
  def cached_output(context)
    output(context)
  end
end

# Plug-in the engine subsystem
class Olelo::Application
  before :show do
    @engine = Engine.find!(@resource, :name => params[:output] || params[:engine])
    context = Context.new(:app      => self,
                          :resource => @resource,
                          :params   => params,
                          :request  => request,
                          :response => response,
                          :logger   => logger,
                          :engine   => @engine)
    @content = @engine.cached_output(context)
    if @engine.layout?
      if request.xhr?
        content_type 'text/plain'
        halt @content
      else
        halt render(:show)
      end
    else
      content_type @engine.mime(@resource).to_s
      halt @content
    end
  end

  hook :layout do |name, doc|
    doc.css('#menu .action-view').each do |link|
      engines = Olelo::Engine.find_all(@resource)
      li = engines.select {|e| e.layout? }.map do |e|
        name = escape_html Olelo::I18n.translate("engine_#{e.name}", :fallback => e.name.tr('_', ' '))
        %{<li#{@engine && e.name == @engine.name ? ' class="selected"': ''}>
          <a href="#{escape_html resource_path(@resource, :output => e.name)}">#{name}</a></li>}.unindent
      end +
      engines.select {|e| !e.layout? }.map do |e|
        name = escape_html Olelo::I18n.translate("engine_#{e.name}", :fallback => e.name.tr('_', ' '))
        %{<li class="download#{@engine && e.name == @engine.name ? 'selected': ''}">
                <a href="#{escape_html resource_path(@resource, :output => e.name)}">#{name}</a></li>}.unindent
      end
      link.after "<ul>#{li.join}</ul>"
    end
  end
end

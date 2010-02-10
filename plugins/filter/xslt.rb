author       'Daniel Mendler'
description  'Basic XSLT filter'
dependencies 'engine/filter', 'gem:nokogiri >= 1.4.1'
autoload 'Nokogiri', 'nokogiri'

class Wiki::XSLT < Filter
  def initialize(name, path)
    super(name)
    content = File.read(File.join(File.dirname(__FILE__), path))
    @xslt   = Nokogiri::XSLT(content)
  end

  def params
    { :title => context.resource.title, :path => context.resource.path }.with_indifferent_access
  end

  def filter(content)
    doc = Nokogiri::XML(content)
    # FIXME: quote_params not necessary anymore in nokogiri 1.4.2
    params = Nokogiri::XSLT.quote_params(self.params.to_hash)
    @xslt.apply_to(doc, params)
  end
end

Filter.metaclass.redefine_method :get do |name|
  if name.to_s =~ /\.xsl$/
    XSLT.new(name, name)
  else
    super(name)
  end
end

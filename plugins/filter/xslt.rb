author       'Daniel Mendler'
description  'Basic XSLT filter'
dependencies 'engine/filter'

class Wiki::XSLT < Filter
  def initialize(name, path)
    super(name)
    content = File.read(File.join(File.dirname(__FILE__), path))
    @xslt   = Nokogiri::XSLT(content)
  end

  def params
    context.resource.metadata.merge(:title => context.resource.title, :path => context.resource.path)
  end

  def filter(content)
    @xslt.apply_to(Nokogiri::XML(content),
                   Nokogiri::XSLT.quote_params(self.params.to_hash))
  end
end

Filter.metaclass.redefine_method :get do |name|
  if name.to_s =~ /\.xsl$/
    XSLT.new(name, name)
  else
    super(name)
  end
end

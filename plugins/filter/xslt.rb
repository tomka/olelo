description  'Basic XSLT filter'
dependencies 'engine/filter'

class Olelo::XSLT < Filter
  def initialize(options)
    super
    content = File.read(File.join(File.dirname(__FILE__), options[:stylesheet]))
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

Filter.register :xslt, Olelo::XSLT

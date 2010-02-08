author       'Daniel Mendler'
description  'Basic XSLT filter'
dependencies 'engine/filter', 'gem:nokogiri >= 1.4.1'
autoload 'Nokogiri', 'nokogiri'

class ::XSLT < Filter
  def params
    { :title => context.resource.title }.with_indifferent_access
  end

  def filter(content)
    xslt  = Nokogiri::XSLT(stylesheet)
    doc = Nokogiri::XML(content)
    # FIXME: quote_params not necessary anymore in nokogiri 1.4.2
    params = Nokogiri::XSLT.quote_params(self.params.to_hash)
    xslt.apply_to(doc, params)
  end
end

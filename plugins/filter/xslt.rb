author       'Daniel Mendler'
description  'Basic XSLT filter'
dependencies 'engine/filter', 'gem:nokogiri'
autoload 'Nokogiri', 'nokogiri'

class ::XSLT < Filter
  def params
    { :title => context.resource.title,
      :date => Time.now }
  end

  def filter(content)
    xslt  = Nokogiri::XSLT(stylesheet)
    doc = Nokogiri::XML(content)
    params = Nokogiri::XSLT.quote_params(self.params)
    xslt.transform(doc, params).to_s
  end
end

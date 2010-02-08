author       'Daniel Mendler'
description  'S5 presentation filter'
dependencies 'filter/xslt'

Wiki::App.assets 'ui/**/*'

class S5 < XSLT
  def params
    page = context.page
    s5 = page.metadata['s5'] || {}
    super.merge(s5).merge(:style => (context.params[:style] || s5['style'] || 'advanced'))
  end

  def stylesheet
    File.read(File.join(File.dirname(__FILE__), 's5.xsl'))
  end
end

Filter.register S5.new(:s5)

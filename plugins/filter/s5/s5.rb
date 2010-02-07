author       'Daniel Mendler'
description  'S5 presentation filter'
dependencies 'filter/xslt'

Wiki::App.assets 'data/**/*'

class S5 < XSLT
  def params
    super.merge(:style => context.params[:style] || 'advanced_gfx')
  end

  def stylesheet
    File.read(File.join(File.dirname(__FILE__), 's5.xsl'))
  end
end

Filter.register S5.new(:s5)

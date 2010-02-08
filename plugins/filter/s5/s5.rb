author       'Daniel Mendler'
description  'S5 presentation filter'
dependencies 'filter/xslt'

Wiki::App.assets 'ui/**/*'

class S5 < XSLT
  def params
    metadata = context.page.metadata
    super.merge(metadata).merge(:theme => (context.params[:theme] || metadata['theme'] || 'advanced'))
  end

  def stylesheet
    File.read(File.join(File.dirname(__FILE__), 's5.xsl'))
  end
end

Filter.register S5.new(:s5)

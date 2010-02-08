author       'Daniel Mendler'
description  'LaTeX presentation filter'
dependencies 'filter/xslt'

Wiki::App.assets 'ui/**/*'

class LaTeX < XSLT
  def stylesheet
    File.read(File.join(File.dirname(__FILE__), 'xhtml2latex.xsl'))
  end
end

Filter.register LaTeX.new(:latex)

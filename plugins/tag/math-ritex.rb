author       'Daniel Mendler'
description  'LaTeX -> MathML support via ritex'
dependencies 'filter/tag', 'misc/mathml', 'gem:ritex'
require      'ritex'

Tag.define :math do |context, attrs, content|
  MathML.replace_entities Ritex::Parser.new.parse(content)
end

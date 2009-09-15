dependencies 'filter/tag', 'misc/mathml'
require      'ritex'
author       'Daniel Mendler'
description  'LaTeX -> MathML support via ritex'

Tag.define :math do |context, attrs, content|
  MathML.replace_entities Ritex::Parser.new.parse(content)
end

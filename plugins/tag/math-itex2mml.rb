dependencies 'filter/tag', 'misc/mathml'
require      'open3'
author       'Daniel Mendler'
description  'LaTeX -> MathML support via itex2MML'

# Check for installed version
`itex2MML --version`

Tag.define :math do |context, attrs, content|
  MathML.replace_entities Open3.popen3('itex2MML --inline') { |stdin, stdout, stderr|
    stdin << content.strip
    stdin.close
    stdout.read
  }
end

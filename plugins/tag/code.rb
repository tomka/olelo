author       'Daniel Mendler'
description  'Syntax highlighting tag'
dependencies 'filter/tag', 'utils/pygments'

Tag.define(:code, :requires => :lang) do |context, attrs, content|
  Pygments.pygmentize(content, attrs['lang'])
end

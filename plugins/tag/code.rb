author       'Daniel Mendler'
description  'Syntax highlighting tag'
dependencies 'filter/tag', 'misc/pygments'

Tag.define(:code, :requires => :language) do |context, attrs, content|
  Pygments.pygmentize(content, :format => attrs['language'])
end

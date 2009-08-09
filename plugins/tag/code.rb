dependencies 'filter/tag', 'misc/pygments'
author       'Daniel Mendler'
description  'Syntax highlighting tag'

Tag.define(:code, :requires => :language) do |context, attrs, content|
  Pygments.pygmentize(content, :format => attrs['language'])
end

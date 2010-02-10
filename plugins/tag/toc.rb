author       'Daniel Mendler'
description  'Tag for auto-generated table of contents'
dependencies 'filter/tag'

Tag.define(:toc) do |context, attrs, content|
  context.private[:toc] ||= true
  '<span class="toc"></span>'
end

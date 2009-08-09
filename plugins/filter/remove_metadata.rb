author       'Daniel Mendler'
description  'Removes metadata header'
dependencies 'engine/filter'

Filter.create :remove_metadata do |content|
  content.sub(/\A---\r?\n(.*?)(\r?\n)---\r?\n/m, '')
end

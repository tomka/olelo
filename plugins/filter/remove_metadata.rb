author       'Daniel Mendler'
description  'Removes metadata header'
dependencies 'engine/filter'

Filter.create :remove_metadata do |content|
  content.sub!(YAML_REGEX, '')
  content
end

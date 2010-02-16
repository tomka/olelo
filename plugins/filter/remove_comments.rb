author       'Daniel Mendler'
description  'Remove html comments'
dependencies 'engine/filter'

Filter.create :remove_comments do |content|
  content.gsub!(/<!--.*?-->/m, '')
  content
end

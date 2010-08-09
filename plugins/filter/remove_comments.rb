description  'Remove html comments'
dependencies 'engine/filter'

Filter.create :remove_comments do |context, content|
  content.gsub!(/<!--.*?-->/m, '')
  content
end

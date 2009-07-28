depends_on 'engine/filter'

Filter.create :remove_metadata do |content|
  content.sub(/\A---\r?\n(.*?)(\r?\n)---\r?\n/m, '')
end

depends_on 'engine/filter'

Filter.create :shebang do |content|
  content.sub(/^#!(\w+)\s+/,'')
end

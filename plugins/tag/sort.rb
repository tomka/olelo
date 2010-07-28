description  'Sort tag'
dependencies 'filter/tag'

Tag.define(:sort) do |context, attrs, content|
  type = attrs['ordered'].to_s.downcase == 'true' ? 'ol' : 'ul'
  order = attrs['descending'].to_s.downcase == 'true' ? -1 : 1
  %{<#{type}>#{content.strip.split(/\n/).sort {|a,b| (a <=> b) * order }.map {|x| "<li>#{escape_html x}</li>"}.join}</#{type}>}
end


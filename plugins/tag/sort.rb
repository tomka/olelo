author       'Daniel Mendler'
description  'Sort tag'
dependencies 'filter/tag'

Tag.define(:sort) do |context, attrs, content|
  type = attrs['ordered'].to_s.downcase == 'true' ? :ol : :ul
  order = attrs['descending'].to_s.downcase == 'true' ? -1 : 1
  builder do
    send(type) do
      content.strip.split(/\n/).sort {|a,b| (a <=> b) * order }.each {|x| li(x) }
    end
  end
end

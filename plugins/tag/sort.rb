author       'Daniel Mendler'
description  'Sort tag'

Tag.define(:sort) do |context, attrs, content|
  type = attrs['ordered'].to_s.downcase == 'true' ? 'ol' : 'ul'
  desc = attrs['descending'].to_s.downcase == 'true'
  "<#{type}>" + content.strip.split(/\n/).
    sort {|a,b| (a <=> b) * (desc ? -1 : 1) }.
    map {|x| "<li>#{escape_html x}</li>" }.join + "</#{type}>"
end

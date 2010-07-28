author       'Daniel Mendler'
description  'Embed github gists'
dependencies 'filter/tag'
require      'open-uri'
require      'json'

Application.hook :layout do |name, doc|
  doc.css('head').first << '<link rel="stylesheet" href="http://gist.github.com/stylesheets/gist/embed.css" type="text/css"/>'
end

Tag.define :gist, :requires => :id do |context, attrs, content|
  if attrs['id'] =~ /^\d+$/
    body = open("http://gist.github.com/#{attrs['id']}.json").read
    gist = JSON.parse(body)
    gist['div']
  else
    raise ArgumentError, 'Invalid gist id'
  end
end

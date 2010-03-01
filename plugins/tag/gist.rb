author       'Daniel Mendler'
description  'Embed github gists'
dependencies 'filter/tag'
require      'net/http'
require      'json'

class Wiki::Application
  hook(:after_style) do
    '<link rel="stylesheet" href="http://gist.github.com/stylesheets/gist/embed.css" type="text/css"/>' if @context && @context.private[:gist_used]
  end
end

Tag.define :gist, :requires => :id do |context, attrs, content|
  context.private[:gist_used] = true
  if attrs[:id] =~ /^\d+$/
    response = Net::HTTP.start('gist.github.com', 80) {|http| http.get("/#{attrs[:id]}.json") }
    if Net::HTTPSuccess === response
      gist = JSON.parse(response.body)
      gist['div']
    else
      response.error!
    end
  else
    raise ArgumentError, 'Invalid gist id'
  end
end

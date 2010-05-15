author       'Daniel Mendler'
description  'Embed github gists'
dependencies 'filter/tag'
require      'net/http'
autoload 'JSON', 'json'

class Wiki::Application
  hook(:after_style) do
    '<link rel="stylesheet" href="http://gist.github.com/stylesheets/gist/embed.css" type="text/css"/>' if @gist_used
  end

  def gist(id)
    if id =~ /^\d+$/
      response = Net::HTTP.start('gist.github.com', 80) {|http| http.get("/#{id}.json") }
      if Net::HTTPSuccess === response
        @gist_used = true
        gist = JSON.parse(response.body)
        gist['div']
      else
        response.error!
      end
    else
      raise ArgumentError, 'Invalid gist id'
    end
  end
end

Tag.define :gist, :requires => :id do |context, attrs, content|
  context.app.gist(attrs['id'])
end

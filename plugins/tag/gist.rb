author       'Daniel Mendler'
description  'Embed github gists'
dependencies 'filter/tag'
require      'open-uri'
require      'json'

class Wiki::Application
  hook :layout do |name, doc|
    doc.css('head').first << '<link rel="stylesheet" href="http://gist.github.com/stylesheets/gist/embed.css" type="text/css"/>' if @gist_used
  end

  def gist(id)
    if id =~ /^\d+$/
      body = open("http://gist.github.com/#{id}.json").read
      @gist_used = true
      gist = JSON.parse(body)
      gist['div']
    else
      raise ArgumentError, 'Invalid gist id'
    end
  end
end

Tag.define :gist, :requires => :id do |context, attrs, content|
  context.app.gist(attrs['id'])
end

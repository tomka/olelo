author       'Daniel Mendler'
description  'Embed github gists'
dependencies 'filter/tag'

class Wiki::Application
  hook(:after_style) do
    '<link rel="stylesheet" href="http://gist.github.com/stylesheets/gist/embed.css" type="text/css"/>' if @gist_used
  end

  def gist_used!
    @gist_used = true
  end
end

Tag.define :gist, :requires => :id do |context, attrs, content|
  context.app.gist_used!
  %{<div class="gist" id="gist-#{Wiki.html_escape attrs[:id]}"></div>}
end

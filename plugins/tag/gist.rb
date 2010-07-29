description  'Embed github gists'
dependencies 'filter/tag', 'utils/asset_manager'
require      'open-uri'
require      'json'

AssetManager.register_scripts 'gist.css', :priority => 0

Tag.define :gist, :requires => :id do |context, attrs, content|
  if attrs['id'] =~ /^\d+$/
    body = open("http://gist.github.com/#{attrs['id']}.json").read
    gist = JSON.parse(body)
    gist['div']
  else
    raise ArgumentError, 'Invalid gist id'
  end
end

__END__
@@ gist.css
@import url("http://gist.github.com/stylesheets/gist/embed.css");

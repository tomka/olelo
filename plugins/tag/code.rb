depends_on 'filter/tag'
depends_on 'misc/pygments'

Tag.define(:code, :requires => :language) do |context, attrs, content|
  Pygments.pygmentize(content, :format => attrs['language'])
end

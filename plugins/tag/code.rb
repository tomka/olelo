Wiki::Plugin.define 'tag/code' do
  depends_on 'filter/tag'
  depends_on 'misc/pygments'

  Wiki::Tag.define(:code, :requires => :language) do |context, attrs, content|
    Pygments.pygmentize(content, :format => attrs['language'])
  end
end

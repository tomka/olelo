Wiki::Plugin.define 'tag/code' do
  depends_on 'filter/tag'
  depends_on 'misc/pygments'

  Wiki::Tag.define(:code, :requires => :language) do |page, params, attrs, content|
    Pygments.pygmentize(content, :format => attrs['language'], :cache => page.saved?)
  end
end

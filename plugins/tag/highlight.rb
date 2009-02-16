Wiki::Plugin.define 'tag/highlight' do
  load_after 'engine/*'
  depends_on 'tag/support'
  depends_on 'misc/pygments'

  Wiki::Engine.enhance :creole, :textile, :markdown do
    define_tag(:code) do |page, code, attrs|
      Pygments.pygmentize(code, :format => attrs['language'], :cache => page.saved?)
    end
  end
end

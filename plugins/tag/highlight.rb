Wiki::Plugin.define 'tag/highlight' do
  load_after 'engine/*'

  Wiki::Engine.enhance :creole, :textile, :markdown do
    define_tag(:code) do |page, code, attrs|
      Wiki::Highlighter.cached_text(code, attrs['language'], :disabled => !page.saved?)
    end
  end
end

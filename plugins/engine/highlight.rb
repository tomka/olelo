Wiki::Plugin.define 'engine/highlight' do
  depends_on 'misc/pygments'

  Wiki::Engine.create(:highlight, 2, true) do
    accepts { |page| Pygments.supports?(page.name) }

    output do |page|
      Pygments.pygmentize(page.content, :filename => page.name, :cache => page.saved?, :cache_key => page.sha)
    end
  end
end

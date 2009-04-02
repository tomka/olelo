Wiki::Plugin.define 'engine/highlight' do
  depends_on 'misc/pygments'

  Wiki::Engine.create(:highlight, :priority => 2, :layout => true, :cacheable => true) do
    accepts { |page| Pygments.supports?(page.name) }
    output { |context| Pygments.pygmentize(context.page.content, :filename => context.page.name) }
  end
end

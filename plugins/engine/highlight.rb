Wiki::Plugin.define 'engine/highlight' do
  depends_on 'misc/pygments'

  Wiki::Engine.create(:highlight, :priority => 2, :layout => true, :cacheable => true) do
    def accepts?(page); Pygments.supports?(page.name); end
    def output(context); Pygments.pygmentize(context.page.content, :filename => context.page.name); end
  end
end

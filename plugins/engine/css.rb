Wiki::Plugin.define 'engine/css' do
  Wiki::Engine.create(:css, :priority => 6, :layout => false, :cacheable => true) do
    def accepts?(page); page.mime == 'text/x-sass'; end
    def output(context); Sass::Engine.new(context.page.content, :style => :compact).render; end
    def mime(page); 'text/css'; end
  end
end

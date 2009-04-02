Wiki::Plugin.define 'engine/css' do
  Wiki::Engine.create(:css, :priority => 6, :layout => false, :cacheable => true) do
    accepts {|page| page.mime == 'text/x-sass' }
    output  {|page,params| Sass::Engine.new(page.content, :style => :compact).render }
    mime    {|page| 'text/css' }
  end
end

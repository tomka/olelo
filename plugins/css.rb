Mime.add('text/x-sass', %w(sass), %w(text/plain))
Wiki::Engine.create(:css, 6, false) do
  accepts {|page| page.extension == 'sass' }
  output  {|page| Sass::Engine.new(page.content).render }
  mime    {|page| 'text/css' }
end

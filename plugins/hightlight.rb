Wiki::Engine.create(:highlight, 2, true) do
  accepts {|page| Highlighter.installed? && Highlighter.supports?(page.name) }
  output  {|page| Highlighter.file(page.content, page.name) }
end
 

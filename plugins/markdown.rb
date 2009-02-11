require 'rdiscount'

module Wiki
  Mime.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain))
  Engine.create(:markdown, 1, true) do
    accepts {|page| page.mime == 'text/x-markdown' }
    output  {|page| RDiscount.new(page.content).to_html }
  end
end

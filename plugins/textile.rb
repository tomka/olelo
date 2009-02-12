require 'redcloth'

module Wiki
  Mime.add('text/x-textile', %w(textile), %w(text/plain)) do |io|
    io.read(9) == '#!textile'
  end

  Engine.create(:textile, 1, true) do
    accepts {|page| page.mime == 'text/x-textile' }
    output do |page|
      content = page.content.sub(/^#!textile\s+/,'')
      fix_punctuation(RedCloth.new(content).to_html)
    end
  end
end

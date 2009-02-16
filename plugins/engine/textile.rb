Wiki::Plugin.define 'engine/textile' do
  require 'redcloth'
  
  Wiki::Mime.add('text/x-textile', %w(textile), %w(text/plain)) do |io|
    io.read(9) == '#!textile'
  end

  Wiki::Engine.create(:textile, 1, true) do
    accepts {|page| page.mime == 'text/x-textile' }
    output do |page|
      page.content.sub(/^#!textile\s+/,'')
    end
  end
end

Wiki::Plugin.define 'misc/mime' do
  require 'wiki/mime'

  Wiki::Mime.add('text/x-sass', %w(sass), %w(text/plain))

  Wiki::Mime.add('text/x-creole', %w(creole text), %w(text/plain)) do |io|
    io.read(8) == '#!creole'
  end

  Wiki::Mime.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain)) do |io|
    io.read(10) == '#!markdown'
  end

  Wiki::Mime.add('text/x-maruku', %w(maruku), %w(text/plain)) do |io|
    io.read(8) == '#!maruku'
  end

  Wiki::Mime.add('text/x-textile', %w(textile), %w(text/plain)) do |io|
    io.read(9) == '#!textile'
  end
end

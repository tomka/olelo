require 'wiki/mime'

Mime.add('text/x-sass', %w(sass), %w(text/plain))

Mime.add('text/x-creole', %w(creole text), %w(text/plain)) do |io|
  io.read(8) == '#!creole'
end

Mime.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain)) do |io|
  io.read(10) == '#!markdown'
end

Mime.add('text/x-maruku', %w(maruku), %w(text/plain)) do |io|
  io.read(8) == '#!maruku'
end

Mime.add('text/x-textile', %w(textile), %w(text/plain)) do |io|
  io.read(9) == '#!textile'
end

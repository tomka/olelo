require 'wiki/mime'

Mime.add('text/x-sass', %w(sass), %w(text/plain))
Mime.add('text/x-creole', %w(creole text), %w(text/plain), [0, '#!creole'])
Mime.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain), [0, '#!markdown'])
Mime.add('text/x-maruku', %w(maruku), %w(text/plain), [0, '#!maruku'])
Mime.add('text/x-textile', %w(textile), %w(text/plain), [0, '#!textile'])

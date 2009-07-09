require 'mimemagic'

MimeMagic.add('text/x-sass', %w(sass), %w(text/plain))
MimeMagic.add('text/x-creole', %w(creole text), %w(text/plain), [0, '#!creole'])
MimeMagic.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain), [0, '#!markdown'])
MimeMagic.add('text/x-maruku', %w(maruku), %w(text/plain), [0, '#!maruku'])
MimeMagic.add('text/x-textile', %w(textile), %w(text/plain), [0, '#!textile'])
MimeMagic.add('text/x-yaml', %w(yaml yml), %w(text/plain))
MimeMagic.add('text/x-org-mode', %w(org), %w(text/plain))

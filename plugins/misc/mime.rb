author      'Daniel Mendler'
description 'Register some mime types'

MimeMagic.add('text/x-creole', %w(creole text), %w(text/plain), [0..64, 'creole'])
MimeMagic.add('text/x-markdown', %w(markdown md mdown mkdn mdown), %w(text/plain), [0..64, 'markdown'])
MimeMagic.add('text/x-maruku', %w(maruku), %w(text/plain), [0..64, 'maruku'])
MimeMagic.add('text/x-textile', %w(textile), %w(text/plain), [0..64, 'textile'])
MimeMagic.add('text/x-yaml', %w(yaml yml meta), %w(text/plain))
MimeMagic.add('text/x-org-mode', %w(org), %w(text/plain))

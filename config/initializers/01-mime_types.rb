# Register some mime types

MimeMagic.add('text/x-creole',
              :extensions => %w(creole text),
              :parents => 'text/plain',
              :magic => [[0..64, 'creole']],
              :comment => 'Creole Wiki Text File')

MimeMagic.add('text/x-markdown',
              :extensions => %w(markdown md mdown mkdn mdown),
              :parents => 'text/plain',
              :magic => [[0..64, 'markdown']],
              :comment => 'Markdown Text File')

MimeMagic.add('text/x-maruku',
              :extensions =>  'maruku',
              :parents => 'text/plain',
              :magic => [[0..64, 'maruku']],
              :comment => 'Maruku Text File')

MimeMagic.add('text/x-textile',
              :extensions => 'textile',
              :parents => 'text/plain',
              :magic => [[0..64, 'textile']],
              :comment => 'Textile Text File')

MimeMagic.add('text/x-yaml',
              :extensions => %w(yaml yml),
              :parents => 'text/plain',
              :comment => "YAML Ain't Markup Language File")

MimeMagic.add('text/x-orgmode',
              :extensions => 'org',
              :parents => 'text/plain',
              :comment => 'Emacs Orgmode File')

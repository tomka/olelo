description  'Syntax highlighting tag'
dependencies 'filter/tag', 'utils/pygments'

Tag.define :code, :requires => :lang, :description => 'Code with syntax highlighting' do |context, attrs, content|
  Pygments.pygmentize(content, attrs['lang'])
end

description  'Emacs org-mode filter'
dependencies 'engine/filter'
require      'org-ruby'

Filter.create :orgmode do |context, content|
  Orgmode::Parser.new(content).to_html
end

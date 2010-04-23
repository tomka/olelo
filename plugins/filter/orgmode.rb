author       'Daniel Mendler'
description  'Emacs org-mode filter'
dependencies 'engine/filter', 'gem:org-ruby'
autoload 'Orgmode', 'org-ruby'

Filter.create :orgmode do |content|
  Orgmode::Parser.new(content).to_html
end

depends_on 'engine/filter'

# FIXME
Filter.create :orgmode do |content|
  begin
    file = File.new('/tmp/content.org', 'w')
    file.write(content)
    file.close

    `/usr/bin/emacs --batch -l org --eval '(setq org-export-headline-levels 3 org-export-with-toc nil org-export-author-info nil )' --visit='#{file.path}' --funcall org-export-as-html-batch >/dev/null 2>&1`

    result = File.read('/tmp/content.html')
    result =~ /<body>(.*)<\/body>/m;
    $1
  ensure
    File.unlink('/tmp/content.org')
    File.unlink('/tmp/content.html')
  end
end

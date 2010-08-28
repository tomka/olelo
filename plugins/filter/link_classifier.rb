description  'Classify links as absent/present/external'
dependencies 'engine/filter'

Filter.create :link_classifier do |context, content|
  doc = Nokogiri::HTML::DocumentFragment.parse(content)
  doc.css('a[href]').each do |link|
    href =  link['href']
    classes = [link['class']].compact
    if href.begins_with?('http://') || href.begins_with?('https://')
      classes << 'external'
    elsif !href.begins_with?('#')
      path, query = href.split('?')
      path = context.page.path/'..'/path if !path.begins_with? '/'
      classes << 'internal' << (Page.find(path) ? 'present' : 'absent')
    end
    link['class'] = classes.join(' ') if !classes.empty?
  end
  doc.to_xhtml
end

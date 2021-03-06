description  'Classify links as absent/present/external'
dependencies 'engine/filter'

Filter.create :link_classifier do |context, content|
  doc = XMLFragment(content)
  doc.css('a[href]').each do |link|
    href =  link['href']
    classes = [link['class']].compact
    if href.begins_with?('http://') || href.begins_with?('https://')
      classes << 'external'
    elsif !href.begins_with?('#')
      path, query = href.split('?')
      if path.begins_with? Config.base_path
        path = path[Config.base_path.length-1..-1]
      elsif !path.begins_with? '/'
        path = context.page.path/'..'/path
      end
      classes << 'internal'
      if !Application.reserved_path?(path)
        classes << (Page.find(path) ? 'present' : 'absent') rescue nil
      end
    end
    link['class'] = classes.join(' ') if !classes.empty?
  end
  doc.to_xhtml
end

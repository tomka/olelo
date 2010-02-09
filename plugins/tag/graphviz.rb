author       'Daniel Mendler'
description  'Graphviz tags'
dependencies 'filter/tag', 'misc/imaginator'

def define_tag(type)
  Tag.define type do |context, attrs, content|
    raise(RuntimeError, 'Limits exceeded') if content.size > 10240
    name = Plugin['misc/imaginator'].imaginator.enqueue(type, content)
    alt = Wiki.html_escape content
    %{<img src="/_/misc/imaginator/#{name}" alt="#{alt}" class="#{type}"/>}
  end
end

define_tag :dot
define_tag :neato
define_tag :twopi
define_tag :circo
define_tag :fdp

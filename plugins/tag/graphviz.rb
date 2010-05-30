author       'Daniel Mendler'
description  'Graphviz tags'
dependencies 'filter/tag', 'utils/imaginator'

def define_tag(type)
  Tag.define type do |context, attrs, content|
    raise 'Limits exceeded' if content.size > 10240
    name = Plugin['utils/imaginator'].imaginator.enqueue(type, content)
    %{<img src="/_/utils/imaginator/#{name}" alt="#{escape_html content}" class="#{type}"/>}
  end
end

define_tag :dot
define_tag :neato
define_tag :twopi
define_tag :circo
define_tag :fdp

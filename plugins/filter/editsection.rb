description  'Adds links for section editing for creole'
dependencies 'engine/filter'

Application.attribute_editor do
  attribute :noeditlinks, :boolean
end

Filter.create :editsection do |context, content|
  if context.page.new? || context.page.modified? || !context.page.current? || context.page.attributes['noeditlinks']
    subfilter(context, content)
  else
    prefix = "EDIT_#{object_id}_"
    len = content.length
    pos, off = [], 0
    while (off = content.index(/^([ \t]*(=+)(.*?))=*\s*$/, off))
      pos << [$2.size, off, off + $1.size, $3.strip]
      off += $&.size
    end
    off = 0
    pos.each_with_index do |p,i|
      link = " #{prefix}#{i} "
      content.insert(p[2] + off, link)
      off += link.size
    end
    content = subfilter(context, content)
    content.gsub!(/#{prefix}(\d+)/) do |match|
      i = $1.to_i
      l = pos[i+1] ? pos[i+1][1] - pos[i][1] - 1 : len - pos[i][1]
      path = action_path(context.page, :edit) + "?pos=#{pos[i][1]}&len=#{l}&comment=#{pos[i][3]} edited"
      %{<a class="editlink" href="#{escape_html path}" title="Edit section #{escape_html pos[i][3]}">Edit</a>}
    end
    content
  end
end

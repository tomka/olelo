author      'Daniel Mendler'
description 'Adds links for section editing for creole'

Filter.create :editsection do |content|
  if context.page.modified? || !context.page.current?
    subfilter(content)
  else
    prefix = "EDIT_#{unique_id}_"
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
    content = subfilter(content)
    content.gsub!(/#{prefix}(\d+)/) do |match|
      i = $1.to_i
      l = pos[i+1] ? pos[i+1][1] - pos[i][1] - 1 : len - pos[i][1]
      path = action_path(context.page, :edit) + "?pos=#{pos[i][1]}&len=#{l}&message=#{pos[i][3]} edited"
      %{<span class="editlink">[<a href="#{Wiki.html_escape path}" title="Edit section #{Wiki.html_escape pos[i][3]}">Edit</a>]</span>}
    end
    content
  end
end

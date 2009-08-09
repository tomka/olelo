author       'Daniel Mendler'
description  'Adds links for section editing for creole'

Filter.create :editsection do |content|
  if context.page.modified? || !context.page.current?
    subfilter(content)
  else
    prefix = "EDIT_#{Thread.current.object_id.abs.to_s(36)}_"
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
      n = i + 1
      while pos[n + 1] && pos[n][0] > pos[i][0]
        n += 1
      end
      l = if pos[n]
        pos[n][1] - pos[i][1] - 1
      else
        len - pos[i][1]
      end
      msg = escape_html "#{pos[i][3]} edited"
      %Q{<span class="editlink">[<a href="#{action_path(context.page, :edit)}?pos=#{pos[i][1]}&amp;len=#{l}&amp;message=#{msg}">Edit</a>]</span>}
    end
    content
  end
end

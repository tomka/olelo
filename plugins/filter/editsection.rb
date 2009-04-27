Filter.create :editsection do |content|
  return subfilter(content) if !context.page.saved?
  prefix = "EDIT_#{Thread.current.object_id.abs.to_s(36)}_"
  len = content.length
  pos, off = [], 0
  while (off = content.index(/^([ \t]*=+(.*?))=*\s*$/, off))
    pos << [off, off + $1.size, $2.strip]
    off += $&.size
  end
  off = 0
  pos.each_with_index do |p,i|
    link = " #{prefix}#{i} "
    content.insert(p[1] + off, link)
    off += link.size
  end
  content = subfilter(content)
  content.gsub!(/#{prefix}(\d+)/) do |match|
    i = $1.to_i
    p = pos[i][0]
    l = pos[i+1] ? pos[i+1][0] - pos[i][0] - 1 : len - pos[i][0]
    m = escape_html "#{pos[i][2]} edited"
    "<span class=\"editlink\">[<a href=\"#{action_path(context.page, :edit)}?pos=#{p}&amp;len=#{l}&amp;message=#{m}\">Edit</a>]</span>"
  end
  content
end

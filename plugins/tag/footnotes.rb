depends_on 'filter/tag'

Tag.define :ref do |context, attrs, content|
  footnotes = context['__FOOTNOTES__'] ||= []
  hash = context['__FOOTNOTES_HASH__'] ||= {}
  name = attrs['name']
  if content.blank?
    raise(ArgumentError, 'Attribute name missing') if name.blank?
    raise(NameError, "Footnote #{name} not found") if !hash.include?(name)
    note_id = hash[name]
    ref_id = "#{note_id}_#{footnotes[note_id-1][2].size + 1}"
    footnotes[note_id-1][2] << ref_id
  else
    note_id = ref_id = footnotes.size + 1
    footnotes << [note_id, nested_tags(context.subcontext, content), [ref_id]]
    hash[name] = note_id if !name.blank?
  end
  "<a class=\"ref\" id=\"ref#{ref_id}\" href=\"#note#{note_id}\">[#{note_id}]</a>"
end

Tag.define :references do |context, attrs, content|
  footnotes = context['__FOOTNOTES__']
  return nil if !footnotes
  list = '<ol>'
  list += footnotes.map do |id, note, refs|
    links = ''
    refs.each_with_index do |ref, i|
      links << "<a href=\"#ref#{ref}\">&#8593;#{i+1}</a> "
    end
    "<li id=\"note#{id}\">#{links} #{note}</li>"
  end.join("\n")
  list + '</ol>'
end

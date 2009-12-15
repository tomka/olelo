author       'Daniel Mendler'
description  'Footnote support'
dependencies 'filter/tag'

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
    content = subfilter(nested_tags(context.subcontext, content))
    footnotes << [note_id, content.gsub(/^\s*<p>\s*|\s*<\/p>\s*$/, ''), [ref_id]]
    hash[name] = note_id if !name.blank?
  end
  %Q{<a class="ref" id="ref#{ref_id}" href="#note#{note_id}">[#{note_id}]</a>}
end

TEMPLATE = %q{
%ol
  - @footnotes.map do |id, note, refs|
    %li{:id=>"note#{id}"}
      - refs.each_with_index do |ref, i|
        %a.backref{:href=>"#ref#{ref}"}= i+1
      = note
}

Tag.define :references do |context, attrs, content|
  @footnotes = context['__FOOTNOTES__']
  haml TEMPLATE, :layout => false if @footnotes
end

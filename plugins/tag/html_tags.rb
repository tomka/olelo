description  'Safe html tags'
dependencies 'filter/tag'

HTML_TAGS = {
  :a => %w(href title),
  :img => %w(src alt title),
  :br => [],
  :i => [],
  :u => [],
  :b => [],
  :pre => [],
  :kbd => [],
  # provided by syntax highlighter
  # :code => %w(lang),
  :cite => [],
  :strong => [],
  :em => [],
  :ins => [],
  :sup => [],
  :sub => [],
  :del => [],
  :table => [],
  :tr => [],
  :td => %w(colspan rowspan),
  :th => [],
  :ol => %w(start),
  :ul => [],
  :li => [],
  :p => [],
  :h1 => [],
  :h2 => [],
  :h3 => [],
  :h4 => [],
  :h5 => [],
  :h6 => [],
  :blockquote => %w(cite),
  :div => %w(style),
  :span => %w(style),
  :video => %w(autoplay controls height width loop preload src poster),
  :audio => %w(autoplay controls loop preload src)
}

# Extra function because of ruby 1.8 block scoping
def define_html_tag(name, allowed)
  Tag.define name do |context, attrs, content|
    attrs = attrs.map {|(k,v)| %{#{k}="#{escape_html v}"} if allowed.include? k }.compact.join(' ')
    content = subfilter(context.subcontext, content)
    content.gsub!(/(\A<p>)|(<\/p>\Z)/, '')
    "<#{name}#{attrs.blank? ? '' : ' '+attrs}>#{content}</#{name}>"
  end
end

HTML_TAGS.each {|name, allowed| define_html_tag(name, allowed) }

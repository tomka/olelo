author       'Daniel Mendler'
description  'Auto-generated table of contents'
dependencies 'engine/filter', 'filter/tag', 'gem:hpricot'
require      'hpricot'

class Toc < Filter
  def filter(content)
    return content if !context['__TOC__']
    @toc = '<div class="toc">'
    @level = 0
    @doc = Hpricot(content)
    @count = [0]

    elem = (@doc/'h1,h2,h3,h4,h5,h6').first
    @offset = elem ? elem.name[1..1].to_i - 1 : 0

    walk(@doc)
    while @level > 0
      @level -= 1
      @toc << '</li></ul>'
    end
    @toc << '</div>'

    content = @doc.to_html.fix_encoding
    @toc = @toc.fix_encoding

    content.gsub!(context['__TOC__']) do
      prefix = $`
      count = prefix.scan('<p>').size - prefix.scan('</p>').size
      count > 0 ? '</p>' + @toc + '<p>' : @toc
    end
    content.gsub!(%r{<p>\s*</p>}, '')

    content
  end

  private

  def walk(elem)
    elem.each_child do |child|
      next if !child.elem?
      if child.name =~ /^h(\d)$/
        nr = $1.to_i - @offset
        if nr > @level
          while nr > @level
            @toc << '<ul>'
            @count[@level] = 0
            @level += 1
            @toc << '<li>' if nr > @level
          end
        else
          while nr < @level
            @level -= 1
            @toc << '</li></ul>'
          end
          @toc << '</li>'
        end
        @count[@level-1] += 1
        headline = child.children.first ? child.children.first.inner_text : ''
        section = 'section-' + @count[0..@level-1].join('_') + '_' + headline.strip.gsub(/[^\w]/, '_')
        @toc << %{<li class="toc#{@level-@offset+1}"><a href="##{section}">\
<span class="counter">#{@count[@level-1]}</span> #{headline}</a>}
        child.inner_html = %Q{<span class="counter" id="#{section}">#{@count[0..@level-1].join('.')}</span> #{child.inner_html}}
      else
        walk(child)
      end
    end
  end
end

Tag.define(:toc, :immediate => true) do |context, attrs, content|
  context['__TOC__'] ||= "TOC_#{Thread.current.object_id.abs.to_s(36)}"
end

Filter.register Toc.new(:toc)

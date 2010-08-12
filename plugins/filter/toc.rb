description  'Auto-generated table of contents'
dependencies 'engine/filter', 'filter/tag'

class Toc < Filter
  def filter(context, content)
    return content if !context.page.metadata[:toc]

    @toc = ''
    @level = 0
    @doc = Nokogiri::HTML::DocumentFragment.parse(content)
    @count = [0]

    elem = (@doc/'h1,h2,h3,h4,h5,h6').first
    @offset = elem ? elem.name[1..1].to_i - 1 : 0

    @doc.traverse {|child| headline(child) if child.name =~ /^h(\d)$/ }

    while @level > 0
      @level -= 1
      @toc << '</li></ol>'
    end

    @toc + @doc.to_xhtml
  end

  private

  def headline(elem)
    nr = elem.name[1..1].to_i - @offset
    if nr > @level
      while nr > @level
        @toc << (@level == 0 ? '<ol class="toc">' : '<ol>')
        @count[@level] = 0
        @level += 1
        @toc << '<li>' if nr > @level
      end
    else
      while nr < @level
        @level -= 1
        @toc << '</li></ol>'
      end
      @toc << '</li>'
    end
    @count[@level-1] += 1
    headline = elem.children.first ? elem.children.first.inner_text : ''
    section = ['sec', *@count[0..@level-1], headline.strip.gsub(/[^\w]/, '-')].join('-').downcase
    @toc << %{<li class="toc#{@level-@offset+1}"><a href="##{section}">#{headline}</a>}.unindent
    elem.inner_html = %{<span class="number" id="#{section}">#{@count[0..@level-1].join('.')}</span> #{elem.inner_html}}
  end
end

Filter.register :toc, Toc

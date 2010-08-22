# Filter engine configuration engines.rb
# Filter engines consist of multiple filters

################################################################################
# Register some simple regular expression filters which are used later
################################################################################

regexp :remove_comments, /<!--.*?-->/m,      ''
regexp :math_shortcuts,  /\$\$(.*?)\$\$/m,   '<math display="inline">\1</math>',
                         /\\\((.*?)\\\)/m,   '<math display="inline">\1</math>',
                         /\\\[(.*?)\\\]/m,   '<math display="block">\1</math>'
regexp :creole_nowiki,   /\{\{\{.*?\}\}\}/m, '<notags>\0</notags>'
regexp :textile_nowiki,  /<pre>.*?<\/pre>/m, '<notags>\0</notags>'

################################################################################
# Creole engines configuration
################################################################################

engine :creole do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-creole'
  filter do
    remove_comments
    editsection do
      remove_comments.math_shortcuts
      creole_nowiki.tag { creole!.rubypants }
    end
    toc
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-creole'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    creole_nowiki.tag { creole!.rubypants }
    toc.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-creole'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    creole_nowiki.tag { creole!.rubypants }
    toc.html_wrapper!.xslt!(:stylesheet => 'xhtml2latex.xsl')
  end
end

################################################################################
# Textile engines configuration
################################################################################

engine :textile do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-textile'
  filter do
    remove_comments.math_shortcuts
    textile_nowiki.tag { textile!.rubypants }
    toc
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-textile'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    textile_nowiki.tag { textile!.rubypants }
    toc.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-textile'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    textile_nowiki.tag { textile!.rubypants }
    toc.html_wrapper!.xslt!(:stylesheet => 'xhtml2latex.xsl')
  end
end

################################################################################
# Markdown engines configuration
################################################################################

engine :markdown do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-markdown'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { markdown! }
    toc
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { markdown! }
    toc.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { markdown! }
    toc.html_wrapper!.xslt!(:stylesheet => 'xhtml2latex.xsl')
  end
end

################################################################################
# Kramdown engines configuration
################################################################################

engine :kramdown do
  is_cacheable.needs_layout.has_priority(2)
  accepts 'text/x-markdown'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { kramdown! }
    toc
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { kramdown! }
    toc.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { kramdown! }
    toc.html_wrapper!.xslt!(:stylesheet => 'xhtml2latex.xsl')
  end
end

################################################################################
# Maruku engines configuration
################################################################################

engine :maruku do
  is_cacheable.needs_layout.has_priority(3)
  accepts 'text/x-markdown'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { maruku! }
    toc
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { maruku! }
    toc.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { maruku! }
    toc.html_wrapper!.xslt!(:stylesheet => 'xhtml2latex.xsl')
  end
end

################################################################################
# Orgmode engines configuration
################################################################################

engine :orgmode do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-orgmode'
  filter do
    remove_comments.math_shortcuts
    tag { orgmode!.rubypants }
    toc
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-orgmode'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    tag { orgmode!.rubypants }
    toc.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-orgmode'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    tag { orgmode!.rubypants }
    toc.html_wrapper!.xslt!(:stylesheet => 'xhtml2latex.xsl')
  end
end

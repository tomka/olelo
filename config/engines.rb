# Filter engine configuration engines.rb

################################################################################
#
# Register some simple regular expression filters which are used later
#
# Usage:
#   regexp :filter_name, /regex1/, 'replacement1', /regex2/, 'replacement2'
#
################################################################################

regexp :remove_comments, /<!--.*?-->/m,      ''
regexp :math_shortcuts,  /\$\$(.*?)\$\$/m,   '<math display="inline">\1</math>',
                         /\\\((.*?)\\\)/m,   '<math display="inline">\1</math>',
                         /\\\[(.*?)\\\]/m,   '<math display="block">\1</math>'
regexp :creole_nowiki,   /\{\{\{.*?\}\}\}/m, '<notags>\0</notags>'
regexp :textile_nowiki,  /<pre>.*?<\/pre>/m, '<notags>\0</notags>'

################################################################################
#
# Define filter output engines which process pages by sending them
# through multiple filters. DSL methods can be chained.
# Available filters are listed on the /system page.
#
# Example DSL usage:
#
# engine :engine_name do          # Create engine with name "engine_name"
#  is_cacheable                   # Engine supports caching (renders static content)
#  needs_layout                   # Engine needs a html layout around the generated content
#  has_priority 1                 # Engine has priority 1, lower priorities are preferred
#  accepts 'text/x-creole'        # Accepted mime types. This is a regular expression
#  mime    'text/html'            # Generated mime type. Only interesting for engines which don't need a layout.
#  filter do                      # Define filter chain
#    remove_comments              # First filter removes html comments <!--...-->. This filter is defined above.
#    math_shortcuts               # Replace math shortcuts with math tags
#    creole_nowiki                # Replace creole nowiki tags with <notags> to disable tag interpretation (next filter)
#    tag do                       # Interpret wiki tags. Wiki tags are an extension to default wiki text
#      creole!                    # Transform creole to html
#      rubypants                  # Execute rubypants (e.g. replace ... with &hellip;)
#    end
#    toc                          # Auto-generate table of contents
#    link_classifier              # Classify links: Insert classes present for present pages, absent for absent pages, internal, external
#  end
# end
#
################################################################################

################################################################################
# Creole engines configuration
################################################################################

engine :page do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-creole'
  filter do
    editsection do
      remove_comments.math_shortcuts
      creole_nowiki.tag { creole!.rubypants }
    end
    toc.link_classifier
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-creole'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    creole_nowiki.tag { creole!.rubypants }
    toc.link_classifier.html_wrapper!.s5!
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

engine :page do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-textile'
  filter do
    remove_comments.math_shortcuts
    textile_nowiki.tag { textile!.rubypants }
    toc.link_classifier
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-textile'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    textile_nowiki.tag { textile!.rubypants }
    toc.link_classifier.html_wrapper!.s5!
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

engine :page do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-markdown'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { markdown! }
    toc.link_classifier
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { markdown! }
    toc.link_classifier.html_wrapper!.s5!
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

engine :page do
  is_cacheable.needs_layout.has_priority(2)
  accepts 'text/x-markdown'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { kramdown! }
    toc.link_classifier
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { kramdown! }
    toc.link_classifier.html_wrapper!.s5!
  end
end

engine :latex do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'text/plain; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { kramdown!(:latex => true) }
  end
end

################################################################################
# Maruku engines configuration
################################################################################

engine :page do
  is_cacheable.needs_layout.has_priority(3)
  accepts 'text/x-markdown'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { maruku! }
    toc.link_classifier
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-markdown'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    markdown_nowiki.tag { maruku! }
    toc.link_classifier.html_wrapper!.s5!
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

engine :page do
  is_cacheable.needs_layout.has_priority(1)
  accepts 'text/x-orgmode'
  filter do
    remove_comments.math_shortcuts
    tag { orgmode!.rubypants }
    toc.link_classifier
  end
end

engine :s5 do
  is_cacheable
  accepts 'text/x-orgmode'
  mime 'application/xhtml+xml; charset=utf-8'
  filter do
    remove_comments.math_shortcuts
    tag { orgmode!.rubypants }
    toc.link_classifier.html_wrapper!.s5!
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

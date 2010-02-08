def xslt_engine(name, markup, output_mime)
  engine name do
    is_cacheable
    has_priority 2
    accepts "text/x-#{markup}"
    mime output_mime
    filter :remove_metadata, :math
    filter :tag do
      filter markup, :rubypants
    end
    filter :toc, :html, name
  end
end

def markup_engine(markup, priority = 1, accepted = nil)
  accepted ||= "text/x-#{markup}"
  engine markup do
    needs_layout
    is_cacheable
    has_priority priority
    accepts accepted
    filter :remove_metadata, :math
    filter :tag do
      filter markup, :rubypants
    end
    filter :toc
  end

  xslt_engine :s5, markup, 'text/html; charset=utf-8'
  xslt_engine :latex, markup, 'text/plain; charset=utf-8'
end

engine :creole do
  needs_layout
  is_cacheable
  has_priority 1
  accepts 'text/x-creole'
  filter :editsection do
    filter :remove_metadata, :math
    filter :tag do
      filter :creole, :rubypants
    end
  end
  filter :toc
end

xslt_engine :s5, :creole, 'text/html; charset=utf-8'
xslt_engine :latex, :creole, 'text/plain; charset=utf-8'

markup_engine :textile
markup_engine :markdown
markup_engine :maruku, 2, 'text/x-markdown|text/x-maruku'
markup_engine :orgmode

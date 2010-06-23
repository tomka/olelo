def xslt_engine(name, opts = {})
  engine name do
    is_cacheable.has_priority(2).accepts("text/x-#{opts[:markup]}")
    mime opts[:mime]
    filter do
      remove_metadata.remove_comments.math
      tag { filter!(opts[:markup], opts[:options]).rubypants }
      toc.html_wrapper
      filter!(opts[:transformer], opts[:options])
    end
  end
end

def markup_engine(name, opts = {})
  engine name do
    needs_layout.is_cacheable.has_priority(opts[:priority] || 1)
    accepts(opts[:accepts] || "text/x-#{name}")
    filter do
      remove_metadata.remove_comments.math
      tag { filter!(name, opts[:options]).rubypants }
      toc
    end
  end

  xslt_engine :s5, :markup => name, :transformer => :s5, :options => opts[:options], :mime => 'application/xhtml+xml; charset=utf-8'
  xslt_engine :latex, :markup => name, :transformer => :xslt,
              :options => {:stylesheet => 'xhtml2latex.xsl'}.merge(opts[:options] || {}), :mime => 'text/plain; charset=utf-8'
end

engine :creole do
  needs_layout.is_cacheable.has_priority(1)
  accepts 'text/x-creole'
  filter do
    editsection do
      remove_metadata.remove_comments.math
      tag { creole!.rubypants }
    end
    toc
  end
end

xslt_engine :s5_presentation, :markup => :creole, :transformer => :s5, :mime => 'application/xhtml+xml; charset=utf-8'
xslt_engine :latex, :markup => :creole, :transformer => :xslt,
            :options => {:stylesheet => 'xhtml2latex.xsl'}, :mime => 'text/plain; charset=utf-8'

markup_engine :textile
markup_engine :markdown
markup_engine :kramdown, :priority => 2, :accepts => 'text/x-markdown'
markup_engine :maruku, :priority => 2, :accepts => 'text/x-markdown|text/x-maruku'
markup_engine :orgmode
markup_engine :tilt, :options => {:tilt_template => 'textile'}, :priority => 3, :accepts => 'text/x-textile'
markup_engine :tilt, :options => {:tilt_template => 'markdown'}, :priority => 3, :accepts => 'text/x-markdown'

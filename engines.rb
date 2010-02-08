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

engine :s5 do
  is_cacheable
  has_priority 2
  accepts 'text/x-creole'
  mime 'text/html'
  filter :remove_metadata, :math
  filter :tag do
    filter :creole, :rubypants
  end
  filter :toc, :html, :s5
end

engine :textile do
  needs_layout
  is_cacheable
  has_priority 1
  accepts 'text/x-textile'
  filter :remove_metadata, :math
  filter :tag do
    filter :textile, :rubypants
  end
  filter :toc
end

engine :s5 do
  is_cacheable
  has_priority 2
  accepts 'text/x-textile'
  mime 'text/html'
  filter :remove_metadata, :math
  filter :tag do
    filter :textile, :rubypants
  end
  filter :toc, :html, :s5
end

engine :markdown do
  needs_layout
  is_cacheable
  has_priority 1
  accepts 'text/x-markdown'
  filter :remove_metadata, :math
  filter :tag do
    filter :markdown, :rubypants
  end
  filter :toc
end

engine :s5 do
  is_cacheable
  has_priority 2
  accepts 'text/x-markdown'
  mime 'text/html'
  filter :remove_metadata, :math
  filter :tag do
    filter :markdown, :rubypants
  end
  filter :toc, :html, :s5
end

engine :maruku do
  needs_layout
  is_cacheable
  has_priority 1
  accepts 'text/x-maruku'
  filter :remove_metadata, :math
  filter :tag do
    filter :maruku, :rubypants
  end
  filter :toc
end

engine :s5 do
  is_cacheable
  has_priority 2
  accepts 'text/x-maruku'
  mime 'text/html'
  filter :remove_metadata, :math
  filter :tag do
    filter :maruku, :rubypants
  end
  filter :toc, :html, :s5
end

engine :orgmode do
  needs_layout
  is_cacheable
  has_priority 1
  accepts 'text/x-org-mode'
  filter :remove_metadata, :math
  filter :tag do
    filter :orgmode, :rubypants
  end
  filter :toc
end


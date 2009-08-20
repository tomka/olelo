engine :creole do
  needs_layout
  is_cacheable
  has_priority 1
  accepts %r{text/x-creole}
  filter :editsection do
    filter :remove_metadata, :math
    filter :tag do
      filter :creole, :rubypants
    end
  end
  filter :toc
end

engine :textile do
  needs_layout
  is_cacheable
  has_priority 1
  accepts %r{text/x-textile}
  filter :remove_metadata, :math
  filter :tag do
    filter :textile, :rubypants
  end
  filter :toc
end

engine :markdown do
  needs_layout
  is_cacheable
  has_priority 1
  accepts %r{text/x-textile}
  filter :remove_metadata, :math
  filter :tag do
    filter :markdown, :rubypants
  end
  filter :toc
end

engine :maruku do
  needs_layout
  is_cacheable
  has_priority 1
  accepts %r{text/x-maruku}
  filter :remove_metadata, :math
  filter :tag do
    filter :maruku, :rubypants
  end
  filter :toc
end

engine :orgmode do
  needs_layout
  is_cacheable
  has_priority 1
  accepts %r{text/x-textile}
  filter :remove_metadata, :math
  filter :tag do
    filter :orgmode, :rubypants
  end
  filter :toc
end


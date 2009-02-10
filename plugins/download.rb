Wiki::Engine.create(:download, 4, true) do
  accepts {|page| true }
  output  {|page| "<a href=\"#{object_path(page, nil, 'raw')}\">Download</a>" }
end

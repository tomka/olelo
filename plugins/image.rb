Wiki::Engine.create(:image, 1, true) do
  accepts {|page| page.mime.mediatype == 'image' }
  output  {|page| "<img src=\"#{object_path(page, nil, 'raw')}\"/>" }
end
 

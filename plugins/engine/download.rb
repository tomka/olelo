Wiki::Plugin.define 'engine/download' do
  Wiki::Engine.create(:download, 4, true) do
    accepts {|page| true }
    output  {|page| "<a href=\"#{object_path(page, :output => 'raw')}\">Download</a>" }
  end
end

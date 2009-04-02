Wiki::Plugin.define 'engine/fileinfo' do
  Wiki::Engine.create(:fileinfo, :priority => 4, :layout => true) do
    accepts {|page| true }
    output do |page,params|
      "<a href=\"#{object_path(page, :output => 'raw')}\">Download File</a>"
    end
  end
end

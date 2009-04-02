Wiki::Plugin.define 'engine/fileinfo' do
  Wiki::Engine.create(:fileinfo, :priority => 4, :layout => true) do
    accepts {|page| true }
    output do |context|
      "<a href=\"#{object_path(context.page, :output => 'raw')}\">Download File</a>"
    end
  end
end

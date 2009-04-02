Wiki::Plugin.define 'engine/fileinfo' do
  Wiki::Engine.create(:fileinfo, :priority => 4, :layout => true) do
    accepts {|page| true }
    output do |context|
      @page = context.page
      haml :fileinfo
    end
  end
end

Wiki::Plugin.define 'engine/fileinfo' do
  Wiki::Engine.create(:fileinfo, :priority => 4, :layout => true, :cacheable => true) do
    def output(context)
      @page = context.page
      haml :fileinfo
    end
  end
end

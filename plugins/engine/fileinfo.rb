author      'Daniel Mendler'
description 'File information engine'
dependencies 'engine/engine'

Engine.create(:fileinfo, :priority => 4, :layout => true, :cacheable => true) do
  def output(context)
    @resource = context.page
    render :fileinfo
  end
end

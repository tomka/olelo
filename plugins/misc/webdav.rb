author      'Daniel Mendler'
description 'Simple webdav interface to the wiki files'

class Wiki::App
  put '/:path' do
    begin
      return super() if request.form_data?
      resource = Page.find!(repository, params[:path])
      with_hooks :page_save, resource do
        resource.write(request.body, :file_uploaded.t(:path => resource.path), @user)
      end
      200
    rescue NotFound => ex
      @logger.error ex
      404
    rescue StandardError => ex
      @logger.error ex
      400
    end
  end

  post '/:path' do
    begin
      return super() if request.form_data?
      Wiki.forbid(:reserved_path.t => reserved_path?(params[:path]))
      resource = Page.new(repository, params[:path])
      with_hooks :page_save, @resource do
        resource.write(request.body, :file_uploaded.t(:path => resource.path), @user)
      end
      201
    rescue NotFound => ex
      @logger.error ex
      404
    rescue StandardError => ex
      @logger.error ex
      400
    end
  end

  # TODO: Implement more methods if they are needed
  add_route('PROPFIND', '/:path')  { 404 }
  add_route('PROPPATCH', '/:path') { 400 }
  add_route('MKCOL', '/:path')     { 400 }
  add_route('COPY', '/:path')      { 400 }
  add_route('MOVE', '/:path')      { 400 }
  add_route('LOCK', '/:path')      { 400 }
  add_route('UNLOCK', '/:path')    { 400 }
end

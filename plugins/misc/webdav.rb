author      'Daniel Mendler'
description 'Simple webdav interface to the wiki files'

class Wiki::App
  put '/:path' do
    return super() if request.form_data?
    begin
      resource = Page.find!(repository, params[:path])
      with_hooks :page_save, resource do
        resource.write(request.body, :file_uploaded.t(:path => resource.path), user)
      end
      :ok
    rescue NotFound => ex
      logger.error ex
      :not_found
    rescue StandardError => ex
      logger.error ex
      :bad_request
    end
  end

  post '/:path' do
    return super() if request.form_data?
    begin
      Wiki.error :reserved_path.t if reserved_path?(params[:path])
      resource = Page.new(repository, params[:path])
      with_hooks :page_save, resource do
        resource.write(request.body, :file_uploaded.t(:path => resource.path), user)
      end
      :created
    rescue NotFound => ex
      logger.error ex
      :not_found
    rescue StandardError => ex
      logger.error ex
      :bad_request
    end
  end

  # TODO: Implement more methods if they are needed
  add_route('PROPFIND', '/:path')  { :not_found }
  add_route('PROPPATCH', '/:path') { :not_implemented }
  add_route('MKCOL', '/:path')     { :not_implemented }
  add_route('COPY', '/:path')      { :not_implemented }
  add_route('MOVE', '/:path')      { :not_implemented }
  add_route('LOCK', '/:path')      { :not_implemented }
  add_route('UNLOCK', '/:path')    { :not_implemented }
end

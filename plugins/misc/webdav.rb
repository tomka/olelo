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
      halt 200
    rescue NotFound => ex
      @logger.error ex
      halt 404
    rescue StandardError => ex
      @logger.error ex
      halt 400
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
      halt 201
    rescue NotFound => ex
      @logger.error ex
      halt 404
    rescue StandardError => ex
      @logger.error ex
      halt 400
    end
  end

  propfind '/:path' do
    halt 404
  end
end

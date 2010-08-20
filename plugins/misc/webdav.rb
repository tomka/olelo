description 'Simple webdav interface to the wiki files'

class Olelo::Application
  def self.add_webdav_routes
    put '/:path' do
      return super() if request.form_data?
      begin
        page = Page.find!(params[:path])
        with_hooks :save, page do
          Resource.transaction(:page_uploaded.t(:path => page.path), user) do
            page.content = request.body
            page.save
          end
        end
        :ok
      rescue NotFound => ex
        logger.error ex
        :not_found
      rescue Exception => ex
        logger.error ex
        :bad_request
      end
    end

    post '/:path' do
      return super() if request.form_data?
      begin
        raise :reserved_path.t if reserved_path?(params[:path])
        page = Page.new(params[:path])
        with_hooks :save, page do
          Resource.transaction(:page_uploaded.t(:path => page.path), user) do
            page.content = request.body
            page.save
          end
        end
        :created
      rescue NotFound => ex
        logger.error ex
        :not_found
      rescue Exception => ex
        logger.error ex
        :bad_request
      end
    end
  end

  hook :final_routes do
    self.class.add_webdav_routes
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

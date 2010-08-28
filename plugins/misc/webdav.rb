description 'Simple webdav interface to the wiki files'

class Olelo::Application
  redefine_method :save_page do
    return super() if request.form_data?
    begin
      page = request.put? ? Page.find!(params[:path]) : Page.new(params[:path])
      raise :reserved_path.t if reserved_path?(page.path)
      with_hooks :save, page do
        Page.transaction(:page_uploaded.t(:page => page.title), user) do
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

  # TODO: Implement more methods if they are needed
  metaclass.redefine_method :final_routes do
    super()
    add_route('PROPFIND', '/(:path)')  { :not_found }
    add_route('PROPPATCH', '/(:path)') { :not_implemented }
    add_route('MKCOL', '/(:path)')     { :not_implemented }
    add_route('COPY', '/(:path)')      { :not_implemented }
    add_route('MOVE', '/(:path)')      { :not_implemented }
    add_route('LOCK', '/(:path)')      { :not_implemented }
    add_route('UNLOCK', '/(:path)')    { :not_implemented }
  end
end

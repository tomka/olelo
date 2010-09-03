description 'Simple webdav interface to the wiki files'

class Olelo::Application
  def webdav_post
    page = request.put? ? Page.find!(params[:path]) : Page.new(params[:path])
    raise :reserved_path.t if self.class.reserved_path?(page.path)
    Page.transaction(:page_uploaded.t(:page => page.title)) do
      page.content = request.body
      page.save
    end
    :created
  rescue NotFound => ex
    logger.error ex
    :not_found
  rescue Exception => ex
    logger.error ex
    :bad_request
  end

  # TODO: Implement more methods if they are needed
  metaclass.redefine_method :final_routes do
    super()

    put '/(:path)' do
      if request.form_data?
        :not_implemented
      else
        webdav_post
      end
    end

    post '/(:path)' do
      if request.form_data?
        super()
      else
        webdav_post
      end
    end

    add_route('PROPFIND', '/(:path)')  { :not_found }
    add_route('PROPPATCH', '/(:path)') { :not_implemented }
    add_route('MKCOL', '/(:path)')     { :not_implemented }
    add_route('COPY', '/(:path)')      { :not_implemented }
    add_route('MOVE', '/(:path)')      { :not_implemented }
    add_route('LOCK', '/(:path)')      { :not_implemented }
    add_route('UNLOCK', '/(:path)')    { :not_implemented }
  end
end

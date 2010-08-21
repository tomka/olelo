description 'Disallow anonymous access'

class Olelo::Application
  PUBLIC_ACCESS = %w(/login)

  hook :layout, 999 do |name, doc|
    doc.css('#menu .wiki, #info, #search, #sidebar *, script[src*=assets], link[href*=assets], form[action*=signup], #tabheader-signup').remove if user.anonymous?
  end

  before :routing do
    if user.anonymous?
      if !PUBLIC_ACCESS.include?(request.path_info)
        session[:goto] = request.path_info if request.path_info !~ %r{^/_/}
	redirect '/login'
      end
    end
  end
end

description 'Read-only wiki'

class Olelo::Application
  hook :layout, 999 do |name, doc|
    doc.css('#menu .wiki, #info, .editlink').remove if user.anonymous?
  end

  before :routing do
    redirect '/login' if user.anonymous? && request.path_info == '/signup'
  end

  before(:save, 999) do |page|
    raise(AccessDenied) if user.anonymous?
  end

  before(:delete, 999) do |page|
    raise(AccessDenied) if user.anonymous?
  end

  before(:move, 999) do |page, destination|
    raise(AccessDenied) if user.anonymous?
  end
end

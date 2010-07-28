author      'Daniel Mendler'
description 'Read-only wiki'

class Wiki::Application
  hook :layout, 999 do |name, doc|
    doc.css('#menu .wiki, #info, .editlink').remove if user.anonymous?
  end

  before :routing do
    redirect '/login' if user.anonymous? && request.path_info == '/signup'
  end

  before(:save, 999) do |resource|
    raise(AccessDenied) if user.anonymous?
  end

  before(:delete, 999) do |resource|
    raise(AccessDenied) if user.anonymous?
  end

  before(:move, 999) do |resource, destination|
    raise(AccessDenied) if user.anonymous?
  end
end

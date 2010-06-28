author      'Daniel Mendler'
description 'Disallow anonymous access'

class Wiki::Application
  WHITE_LIST =
    [
     '/login',
     '/screen\.css',
     '/print\.css',
     '/reset\.css',
     '/_/user'
    ]

  def public_access?
    WHITE_LIST.any? {|pattern| request.path_info =~ /^#{pattern}$/ }
  end

  hook :menu, 999 do |menu|
    menu.css('ul.wiki').remove if user.anonymous?
  end

  before :routing do
    if user.anonymous?
      halt if request.path_info == '/_/sidebar'
      if !public_access?
        session[:goto] = request.path_info if request.path_info !~ %r{^/_/}
	redirect '/login'
      end
    end
  end
end

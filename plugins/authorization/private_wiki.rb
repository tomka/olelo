author      'Daniel Mendler'
description 'Disallow anonymous access'

class Wiki::App
  WHITE_LIST =
    [
     '/login',
     '/screen\.css',
     '/print\.css',
     '/reset\.css',
     '/sys/user'
    ]

  def public_access?
    WHITE_LIST.any? {|pattern| request.path_info =~ /^#{pattern}$/ }
  end

  add_hook(:before_routing) do
    if @user.anonymous?
      halt if request.path_info == '/sys/sidebar'
      if !public_access?
        session[:goto] = request.path_info if request.path_info !~ %r{^/sys/}
	redirect '/login'
      end
    end
  end
end

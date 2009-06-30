module Wiki::Helper
  alias cache_control_without_auth cache_control

  def cache_control(opts)
    cache_control_without_auth(opts.merge(:private => true))
  end
end

class Wiki::App
  WHITE_LIST =
    [
     '/login',
     '/screen\.css',
     '/print\.css',
     '/reset\.css',
     '/sys/user'
    ]

  add_hook(:before_routing) do
    if @user.anonymous?
      halt if request.path_info == '/sys/sidebar'
      redirect '/login' if !WHITE_LIST.any? {|pattern| request.path_info =~ /^#{pattern}$/ }
    end
  end
end

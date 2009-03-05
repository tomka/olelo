Wiki::Plugin.define 'misc/private_wiki' do
  module Wiki::Helper
    alias cache_control_without_auth cache_control

    def cache_control(opts)
      cache_control_without_auth(opts.merge(:mode => :private))
    end
  end

  class Wiki::App
    WHITE_LIST =
      [
       '/login',
       '/style\.css',
       '/sys/fragments/user'
      ]

    before do
      if !WHITE_LIST.any? {|pattern| request.path_info =~ /^#{pattern}$/ }
        redirect '/login' if @user.anonymous?
      end
    end
  end
end

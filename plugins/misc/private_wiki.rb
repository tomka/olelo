Wiki::Plugin.define 'misc/private_wiki' do
  module Wiki::Helper
    alias sidebar_without_auth sidebar
    def sidebar
      authenticated? ? sidebar_without_auth : ''
    end
  end

  class Wiki::App
    WHITE_LIST =
      [
       '/login',
       '/style.css',
       '/sys/.*'
      ]

    before do
      if !WHITE_LIST.any? {|pattern| request.path_info =~ /^#{pattern}$/ }
        redirect '/login' if !authenticated?
      end
    end

    def authenticated?
      !!session[:user]
    end
  end
end

class Wiki::App
  get '/_/user' do
    hash = Wiki.md5(@user.email)
    %{<a href="/profile"><img src="http://www.gravatar.com/avatar/#{hash}?d=identicon&s=20" alt="Gravatar" style="float: left; margin: -2px 5px -2px 0;"/></a>} + super()
  end
end

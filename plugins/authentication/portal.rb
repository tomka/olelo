author       'Daniel Mendler'
description  'Proprietary web portal based user storage'
dependencies 'gem:hpricot'

User.define_service(:portal) do
  autoload 'Hpricot', 'hpricot'
  autoload 'OpenSSL', 'openssl'

  def authenticate(name, password)
    require 'open-uri'

    xml = open(Wiki::Config.auth.portal_uri,
               :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
               :http_basic_authentication => [name, password]).read

    # User data is exposed as xml
    doc = Hpricot::XML(xml)
    email = (doc/'person/email').text
    name = (doc/'person/user/name').text
    groups = (doc/'person/groups/group/name').map(&:inner_text)
    raise if name.blank?
    User.new(name, email || "#{name}@localhost", groups)
  rescue
    raise StandardError, 'Wrong username or password'
  end
end

author       'Daniel Mendler'
description  'Proprietary web portal based user storage'
dependencies 'gem:hpricot'

require 'hpricot'
require 'open-uri'
require 'openssl'

User.define_service(:portal) do
  def authenticate(name, password)
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
    raise MultiError, 'Wrong username or password'
  end
end

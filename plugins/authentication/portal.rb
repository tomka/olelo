author       'Daniel Mendler'
description  'Proprietary web portal based user storage'

User.define_service(:portal) do
  autoload 'OpenSSL', 'openssl'

  def authenticate(name, password)
    require 'open-uri'

    xml = open(Wiki::Config.auth.portal_uri,
               :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
               :http_basic_authentication => [name, password]).read
    # User data is exposed as xml
    doc = Nokogiri::XML(xml)
    email = (doc/'person/email').text
    name = (doc/'person/user/name').text
    groups = (doc/'person/groups/group/name').to_a.map(&:text)
    raise AuthenticationError if name.blank?
    email = "#{name}@localhost" if email.blank?
    User.new(name, email, groups)
  rescue
    raise AuthenticationError, :wrong_user_or_pw.t
  end
end

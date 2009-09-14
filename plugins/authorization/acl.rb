author      'Daniel Mendler'
description 'Access control lists'

class Wiki::Resource
  def access?(type, user = nil)
    acl = metadata['acl'] || {}
    users = [acl[type.to_s]].flatten.compact
    users.empty? ||
    users.include?('all') || users.include?('*') ||
    user && !user.anonymous? && (users.include?('user') || users.include?(user.name))
  end
end

class Wiki::AccessDenied < StandardError
  def initialize
    super('Access denied')
  end
end

class Wiki::App
  add_hook(:after_action) do |method, action|
    if @resource && method == :get
      @resource.access?(:read, @user) || raise(AccessDenied)

      if !@resource.access?(:read) && response['Cache-Control']
        response['Cache-Control'].sub!(/^public/, 'private')
      end
    end
  end

  add_hook(:before_page_save) do |resource|
    @resource.access?(:write, @user) || raise(AccessDenied)
  end
end

author      'Daniel Mendler'
description 'Access control lists'

class Wiki::Resource
  def access?(type, user = nil)
    acl = metadata['acl'] || {}
    names = [acl[type.to_s]].flatten.compact
    names.empty? ||
    names.include?(user.name) ||
    user.groups.any? {|group| names.include?('@'+group) }
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
    end
  end

  add_hook(:before_page_save) do |resource|
    resource.access?(:write, @user) || raise(AccessDenied)
  end
end

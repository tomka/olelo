author      'Daniel Mendler'
description 'Access control lists'

class Wiki::Resource
  # Resource must be readable and parents must recursively be readable
  def readable?(user)
    access?(:read, user) && (root? || parent.readable?(user))
  end

  # New resource is writable if parent is writable
  # Existing resource is writable if resource is writable and parents are readable
  def writable?(user)
    if root?
      access?(:write, user)
    elsif new?
      parent.writable?(user)
    else
      access?(:write, user) && parent.readable?(user)
    end
  end

  # Resource is deletable if parent is writable
  def deletable?(user)
    parent.writable?(user)
  end

  # Resource is movable if parent is writable and destination is writable
  def movable?(user, destination = nil)
    deletable?(user) && (!destination || Tree.find(destination).writable?(user))
  end

  private

  def access?(type, user = nil)
    acl = metadata['acl'] || {}
    names = [*acl[type.to_s]].compact
    names.empty? ||
    names.include?(user.name) ||
    user.groups.any? {|group| names.include?('@'+group) }
  end
end

class Wiki::AccessDenied < RuntimeError
  def initialize
    super('Access denied')
  end

  def status
    :forbidden
  end
end

class Wiki::Application
  hook :layout, 999 do |name, doc|
    if @resource
      doc.css('#menu a.action-edit').first.delete('href') if !@resource.writable?(user)
      if !@resource.root?
        doc.css('#menu a.action-delete').first.parent.remove if !@resource.deletable?(user)
        doc.css('#menu a.action-move').first.parent.remove if !@resource.movable?(user)
      end
    end
  end

  hook AccessDenied do |ex|
    cache_control :no_cache => true
    @resource = nil
    halt render(:access_denied)
  end

  after :action do |method, action|
    if @resource && method == :get
      @resource.readable?(user) || raise(AccessDenied)
    end
  end

  before(:save, 999) do |resource|
    resource.writable?(user) || raise(AccessDenied)
  end

  before(:delete, 999) do |resource|
    resource.deletable?(user) || raise(AccessDenied)
  end

  before(:move, 999) do |resource, destination|
    resource.movable?(user, destination) || raise(AccessDenied)
  end
end

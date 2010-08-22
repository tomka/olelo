description 'Access control lists'

class Olelo::Page
  # Page must be readable and parents must recursively be readable
  def readable?(user)
    access?(:read, user) && (root? || parent.readable?(user))
  end

  # New page is writable if parent is writable
  # Existing page is writable if page is writable and parents are readable
  def writable?(user)
    if root?
      access?(:write, user)
    elsif new?
      parent.writable?(user)
    else
      access?(:write, user) && parent.readable?(user)
    end
  end

  # Page is deletable if parent is writable
  def deletable?(user)
    parent.writable?(user)
  end

  # Page is movable if parent is writable and destination is writable
  def movable?(user, destination = nil)
    deletable?(user) && (!destination || (Page.find(destination) || Page.new(destination)).writable?(user))
  end

  private

  def access?(type, user = nil)
    acl = attributes['acl'] || {}
    names = [*acl[type.to_s]].compact
    names.empty? ||
    names.include?(user.name) ||
    user.groups.any? {|group| names.include?('@'+group) }
  end
end

class Olelo::AccessDenied < RuntimeError
  def initialize
    super(:access_denied.t)
  end

  def status
    :forbidden
  end
end

class Olelo::Application
  attribute_editor do
    group :acl do
      attribute :read, :stringlist
      attribute :write, :stringlist
    end
  end

  hook :layout, 999 do |name, doc|
    if page
      doc.css('#menu .action-edit').each {|link| link.delete('href') } if !page.writable?(user)
      if !page.root?
        doc.css('#menu .action-delete').each {|link| link.parent.remove } if !page.deletable?(user)
        doc.css('#menu .action-move').each {|link| link.parent.remove } if !page.movable?(user)
      end
    end
  end

  hook AccessDenied do |ex|
    cache_control :no_cache => true
    @page = nil
    session[:goto] = request.path_info if request.path_info !~ %r{^/_/}
    halt render(:access_denied)
  end

  after :action do |method, action|
    if page && method == :get
      page.readable?(user) || raise(AccessDenied)
    end
  end

  before(:save, 999) do |page|
    page.writable?(user) || raise(AccessDenied)
  end

  before(:delete, 999) do |page|
    page.deletable?(user) || raise(AccessDenied)
  end

  before(:move, 999) do |page, destination|
    page.movable?(user, destination) || raise(AccessDenied)
  end
end

__END__
@@ access_denied.haml
- title :access_denied.t
%h1= :access_denied.t
= :access_denied_long.t

description 'Access control lists'

class Olelo::AccessDenied < RuntimeError
  def initialize
    super(:access_denied.t)
  end

  def status
    :forbidden
  end
end

class Olelo::Page
  # Page must be readable and parents must recursively be readable
  def readable?
    access?(:read) && (root? || parent.readable?)
  end

  # New page is writable if parent is writable
  # Existing page is writable if page is writable and parents are readable
  def writable?
    if root?
      access?(:read) && access?(:write)
    elsif new?
      parent.writable?
    else
      access?(:read) && access?(:write) && parent.readable?
    end
  end

  # Page is deletable if parent is writable
  def deletable?
    parent.writable?
  end

  # Page is movable if parent is writable and destination is writable
  def movable?(destination = nil)
    deletable? && (!destination || (Page.find(destination) || Page.new(destination)).writable?)
  end

  before(:save, 999) do
    raise(AccessDenied) if !writable?
  end

  before(:delete, 999) do
    raise(AccessDenied) if !deletable?
  end

  before(:move, 999) do |destination|
    raise(AccessDenied) if !movable?(destination)
  end

  metaclass.redefine_method(:find!) do |*args|
    begin
      super(*args).tap {|page| raise(AccessDenied) if !page.readable? }
    rescue NotFound
      # Forbid probing of pages which are in unreadable folders
      raise(AccessDenied) if !Page.new(*args).readable?
      raise
    end
  end

  private

  def access?(type)
    acl = saved_attributes['acl'] || {}
    names = [*acl[type.to_s]].compact
    names.empty? ||
    names.include?(User.current.name) ||
    User.current.groups.any? {|group| names.include?('@'+group) }
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
      doc.css('#menu .action-edit').each {|link| link.delete('href') } if !page.writable?
      if !page.root?
        doc.css('#menu .action-delete').each {|link| link.parent.remove } if !page.deletable?
        doc.css('#menu .action-move').each {|link| link.parent.remove } if !page.movable?
      end
    end
  end

  hook AccessDenied do |ex|
    if request.xhr?
      response['Content-Type'] = 'application/json; charset=utf-8'
      halt '"Access denied"'
    else
      cache_control :no_cache => true
      @page = nil
      session[:goto] = request.path_info if request.path_info !~ %r{^/_/}
      halt render(:access_denied)
    end
  end
end

__END__
@@ access_denied.haml
- title :access_denied.t
%h1= :access_denied.t
= :access_denied_long.t

description 'Git repository backend'
require     'gitrb'

class Gitrb::Diff
  def to_olelo
    Olelo::Diff.new(from && from.to_olelo, to.to_olelo, patch)
  end
end

class Gitrb::Commit
  def to_olelo
    Olelo::Version.new(id, Olelo::User.new(author.name, author.email), date, message, parents.map(&:id))
  end
end

class GitRepository < Repository
  attr_reader :git

  def initialize(config)
    logger = Plugin.current.logger
    logger.info "Opening git repository: #{config.path}"
    @git = Gitrb::Repository.new(:path => config.path, :create => true,
                                 :bare => config.bare, :logger => logger)
    @current_transaction = {}
    @counter = 0
  end

  def transaction(comment, user = nil, &block)
    raise 'Transaction already running' if @current_transaction[Thread.current.object_id]
    @current_transaction[Thread.current.object_id] = []
    git.transaction(comment, user && Gitrb::User.new(user.name, user.email), &block)
    tree_version = git.head.to_olelo
    current_transaction.each {|f| f.call(tree_version) }
  ensure
    @current_transaction.delete(Thread.current.object_id)
  end

  def find_resource(path, tree_version, current, klass = nil)
    commit = !tree_version.blank? ? git.get_commit(tree_version.to_s) : git.head
    return nil if !commit
    object = commit.tree[path]
    return nil if !object
    if klass
      klass.ancestors.include?(object_class(object.type)) ? klass.new(path, commit.to_olelo, current) : nil
    else
      object_class(object.type).new(path, commit.to_olelo, current)
    end
  rescue
    nil
  end

  def find_version(version)
    git.get_commit(version.to_s).to_olelo
  rescue
    nil
  end

  def history(resource)
    git.log(30, nil, resource.path).map(&:to_olelo)
  end

  def version(resource)
    commits = git.log(2, resource.tree_version, resource.path)

    child = nil
    git.git_rev_list('--reverse', '--remove-empty', "#{commits[0]}..", '--', resource.path) do |io|
      child = io.eof? ? nil : git.get_commit(git.set_encoding(io.readline).strip)
    end rescue nil # no error because pipe is closed intentionally

    [commits[1] ? commits[1].to_olelo : nil, commits[0].to_olelo, child ? child.to_olelo : nil]
  end

  def children(resource)
    git.get_commit(resource.tree_version.to_s).tree[resource.path].map do |name, child|
      object_class(child.type).new(resource.path/name, resource.tree_version, resource.current?)
    end
  end

  def read(resource)
    git.get_commit(resource.tree_version.to_s).tree[resource.path].data
  end

  def write(resource, content)
    # FIXME: Gitrb should handle files directly
    content = content.read if content.respond_to? :read
    git.root[resource.path] = Gitrb::Blob.new(:data => content)
    current_transaction << proc {|tree_version| resource.committed(resource.path, tree_version) }
  end

  def move(resource, destination)
    git.root.move(resource.path, destination)
    current_transaction << proc {|tree_version| resource.committed(destination, tree_version) }
  end

  def delete(resource)
    git.root.delete(resource.path)
    current_transaction << proc { resource.committed(resource.path, nil) }
  end

  def diff(from, to, path = nil)
    git.diff(:from => from && from.to_s, :to => to.to_s, :path => path, :detect_renames => true).to_olelo
  end

  def short_version(version)
    version[0..4]
  end

  def clear_cache
    @counter += 1
    if @counter == 10
      git.clear
      @counter = 0
    end
  end

  private

  CLASSES = {:blob => Page, :tree => Tree}

  def object_class(type)
    CLASSES[type] || raise("Invalid object type: #{type}")
  end

  def current_transaction
    @current_transaction[Thread.current.object_id] || raise('No transaction running')
  end
end

Repository.register :git, GitRepository

Application.after(:request) do
  Repository.instance.clear_cache if Repository.instance.respond_to? :clear_cache
end

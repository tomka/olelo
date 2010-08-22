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

  CONTENT_FILE   = 'content'
  ATTRIBUTE_FILE = 'attributes'

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

  def find_page(path, tree_version, current)
    check_path(path)
    commit = !tree_version.blank? ? git.get_commit(tree_version.to_s) : git.head
    return nil if !commit
    object = commit.tree[path]
    return nil if !object
    Page.new(path, commit.to_olelo, current)
  rescue
    nil
  end

  def find_version(version)
    git.get_commit(version.to_s).to_olelo
  rescue
    nil
  end

  def load_history(page, skip, limit)
    git.log(:max_count => limit, :skip => skip, :path => page.path).map(&:to_olelo)
  end

  def load_version(page)
    commits = git.log(:max_count => 2, :start => page.tree_version, :path => page.path)

    child = nil
    git.git_rev_list('--reverse', '--remove-empty', "#{commits[0]}..", '--', page.path) do |io|
      child = io.eof? ? nil : git.get_commit(git.set_encoding(io.readline).strip)
    end rescue nil # no error because pipe is closed intentionally

    [commits[1] ? commits[1].to_olelo : nil, commits[0].to_olelo, child ? child.to_olelo : nil]
  end

  def load_children(page)
    object = git.get_commit(page.tree_version.to_s).tree[page.path]
    if object.type == :tree
      object.map do |name, child|
        Page.new(page.path/name, page.tree_version, page.current?) if !reserved_name?(name)
      end.compact
    else
      []
    end
  end

  def load_content(page)
    object = git.get_commit(page.tree_version.to_s).tree[page.path]
    object = object[CONTENT_FILE] if object.type == :tree
    if object
      content = object.data
      if content.respond_to? :force_encoding
        content.force_encoding(__ENCODING__)
        content.force_encoding(Encoding::BINARY) if !content.valid_encoding?
      end
      content
    else
      ''
    end
  end

  def load_attributes(page)
    object = git.get_commit(page.tree_version.to_s).tree[page.path]
    object = object.type == :tree ? object[ATTRIBUTE_FILE] : nil
    object ? YAML.load(object.data) : {}
  end

  def save(page)
    path = page.path

    check_path(path)

    content = page.content
    content = content.read if content.respond_to? :read
    attributes = page.attributes.empty? ? nil : YAML.dump(page.attributes).sub(/\A\-\-\-\s*\n/s, '')

    names = path.split('/')
    names.pop
    parent = git.root
    names.each do |name|
      object = parent[name]
      break if !object
      if object.type == :blob
        parent.move(name, name/CONTENT_FILE)
        break
      end
      parent = object
    end

    object = git.root[path]

    # Page exists
    if object
      # Page is a tree
      if object.type == :tree
        if attributes
          (object[ATTRIBUTE_FILE] ||= Gitrb::Blob.new).data = attributes
        else
          object.delete(ATTRIBUTE_FILE)
        end
        (object[CONTENT_FILE] ||= Gitrb::Blob.new).data = content
      # Page is a blob
      else
        if attributes
          git.root.move(path, path/CONTENT_FILE)
          git.root[path/CONTENT_FILE].data = content
          git.root[path/ATTRIBUTE_FILE] = Gitrb::Blob.new(:data => attributes)
        else
          git.root[path].data = content
        end
      end
    # Page does not yet exist
    else
      if attributes
        git.root[path/ATTRIBUTE_FILE] = Gitrb::Blob.new(:data => attributes)
        git.root[path/CONTENT_FILE] = Gitrb::Blob.new(:data => content) if !content.blank?
      else
        git.root[path] = Gitrb::Blob.new(:data => content) if !content.blank?
      end
    end

    current_transaction << proc {|tree_version| page.committed(path, tree_version) }
  end

  def move(page, destination)
    check_path(destination)

    git.root.move(page.path, destination)
    current_transaction << proc {|tree_version| page.committed(destination, tree_version) }
  end

  def delete(page)
    git.root.delete(page.path)
    current_transaction << proc { page.committed(page.path, nil) }
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

  def reserved_name?(name)
    ATTRIBUTE_FILE == name || CONTENT_FILE == name
  end

  private

  def check_path(path)
    raise :reserved_path.t if path.split('/').any? {|name| reserved_name?(name) }
  end

  def current_transaction
    @current_transaction[Thread.current.object_id] || raise('No transaction running')
  end
end

Repository.register :git, GitRepository

Application.after(:request) do
  Repository.instance.clear_cache if Repository.instance.respond_to? :clear_cache
end

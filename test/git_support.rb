require 'test/unit'
require 'wiki'

module GitSupport
  def setup
    @repo_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    @repo = Git.init(@repo_path)
    page = Wiki::Page.new(@repo, 'init.txt')
    page.write('This file is used to initialize the repository. It can be deleted.', 'Initialize Repository')
  end

  def teardown
    FileUtils.rm_rf(@repo_path)
  end
end

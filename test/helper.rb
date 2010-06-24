require 'rack/patches'
require 'wiki'
require 'bacon'
require 'rack/test'

module TestHelper
  def load_plugin(*plugins)
    Wiki::Plugin.logger = Logger.new(File.expand_path(File.join(File.dirname(__FILE__), '..', 'test.log')))
    Wiki::Plugin.dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'plugins'))
    Wiki::Plugin.load(*plugins)
    Wiki::Plugin.start
  end

  def create_repository
    String.root_path = 'root'
    Wiki::Repository.instance = nil
    Wiki::Config['repository.type'] = 'git'
    Wiki::Config['repository.git.path'] = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    Wiki::Config[:namespaces] = {:discussion => 'Discussion:', :metadata   => 'Metadata:'}
    load_plugin('repository/git/git')
  end

  def destroy_repository
    String.root_path = nil
    FileUtils.rm_rf(Wiki::Config.repository.git.path)
  end

  def create_page(name, content = 'content')
    p = Wiki::Page.new(name)
    Wiki::Page.transaction 'comment' do
      p.write(content)
    end
  end
end

class Bacon::Context
  include TestHelper
end

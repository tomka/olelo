require 'rack/patches'
require 'olelo'
require 'bacon'
require 'rack/test'

module TestHelper
  def load_plugin(*plugins)
    Olelo::Plugin.logger = Logger.new(File.expand_path(File.join(File.dirname(__FILE__), '..', 'test.log')))
    Olelo::Plugin.dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'plugins'))
    Olelo::Plugin.load(*plugins)
    Olelo::Plugin.start
  end

  def create_repository
    String.root_path = 'root'
    Olelo::Repository.instance = nil
    Olelo::Namespace.reset
    Olelo::Config['repository.type'] = 'git'
    Olelo::Config['repository.git.path'] = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    Olelo::Config[:namespaces] = {:main => ['', 'Metadata:']}
    load_plugin('repository/git/git')
  end

  def destroy_repository
    String.root_path = nil
    FileUtils.rm_rf(Olelo::Config.repository.git.path)
  end

  def create_page(name, content = 'content')
    p = Olelo::Page.new(name)
    Olelo::Page.transaction 'comment' do
      p.write(content)
    end
  end
end

class Bacon::Context
  include TestHelper
end

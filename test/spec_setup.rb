gem 'test-unit', '>= 0'
gem 'test-spec', '>= 0'
gem 'rack-test', '>= 0'

require 'wiki/app'
require 'test/spec'
require 'rack/test'
require 'wiki/resource'

module GitrbHelpers
  def create_repository
    @repo_path = File.expand_path(File.join(File.dirname(__FILE__), '.test'))
    @repo = Gitrb::Repository.new(:path => @repo_path, :create => true,
                                  :bare => true)
    create_page('Home', 'Home content')
  end

  def destroy_repository
    FileUtils.rm_rf(@repo_path)
  end

  def create_page(name, content = 'content')
    p = Wiki::Page.new(@repo, name)
    p.write(content, 'message')
  end
end

class Test::Unit::TestCase
  include GitrbHelpers
end

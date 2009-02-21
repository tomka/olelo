require 'test/unit'
require 'wiki/entry'

module EntrySupport
  def setup
    Wiki::Config.store = File.expand_path(File.join(File.dirname(__FILE__), '.store.yml'))
  end

  def teardown
    File.unlink(Wiki::Config.store) if File.exists?(Wiki::Config.store)
  end
end

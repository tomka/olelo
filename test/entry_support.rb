require 'test/unit'
require 'wiki'

module EntrySupport
  def setup
    @store_path = File.expand_path(File.join(File.dirname(__FILE__), '.store.yml'))
    Entry.store = @store_path
  end

  def teardown
    File.unlink(@store_path) if File.exists?(@store_path)
  end
end

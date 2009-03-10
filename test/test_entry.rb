require 'entry_support'

class TC_Entry < Test::Unit::TestCase
  include EntrySupport

  def test_save_find
    entry = Wiki::Entry.new('entry')
    assert_equal 'entry', entry.name
    assert_equal 0, entry.version
    entry.save
    assert_equal 1, entry.version

    entry = Wiki::Entry.find('entry')
    assert_not_nil entry
    assert_equal 'entry', entry.name
    assert_equal 1, entry.version

    entry.remove
    assert_equal 0, entry.version

    entry = Wiki::Entry.find('entry')
    assert_nil entry
  end

  def test_concurrent_modification
    entry = Wiki::Entry.new('entry')
    entry.save

    a = Wiki::Entry.find('entry')
    b = Wiki::Entry.find('entry')
    assert_not_nil a
    assert_not_nil b

    a.save
    assert_raise Wiki::Entry::ConcurrentModificationError do
      b.save
    end
  end
end

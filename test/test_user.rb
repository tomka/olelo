require 'entry_support'
require 'wiki/user'

class TC_User < Test::Unit::TestCase
  include EntrySupport

  def test_anonymous
    user = Wiki::User.anonymous('1.2.3.4')
    assert user.anonymous?
    assert_equal '1.2.3.4', user.name
    assert_nil user.password
    assert_equal 'anonymous@1.2.3.4', user.email
    assert_equal '1.2.3.4 <anonymous@1.2.3.4>', user.author

    assert_raise Wiki::MessageError do
      user.save
    end
  end

  def test_create_find_authenticate
    assert_raise Wiki::MessageError do
      Wiki::User.create('otto', 'passwd', 'passwd wrong', 'mail@otto.com')
    end

    user = Wiki::User.create('otto', 'passwd', 'passwd', 'mail@otto.com')
    assert !user.anonymous?
    assert_equal 'otto', user.name
    assert_equal 1, user.version
    assert_equal Digest::SHA256.hexdigest('passwd'), user.password
    assert_equal 'mail@otto.com', user.email
    assert_equal 'otto <mail@otto.com>', user.author

    user = Wiki::User.find('otto')
    assert_not_nil user
    assert_instance_of Wiki::User, user

    assert_raise Wiki::MessageError do
      Wiki::User.authenticate('wrong user', 'passwd')
    end

    assert_raise Wiki::MessageError do
      Wiki::User.authenticate('otto', 'wrong passwd')
    end

    assert_nothing_raised do
      Wiki::User.authenticate('otto', 'passwd')
    end
  end

  def test_change_password
    user = Wiki::User.create('otto', 'passwd', 'passwd', 'mail@otto.com')

    assert_raise Wiki::MessageError do
      user.change_password('wrong old', 'new password', 'new password')
    end

    assert_raise Wiki::MessageError do
      user.change_password('passwd', 'new password', 'wrong new password')
    end

    assert_nothing_raised Wiki::MessageError do
      user.change_password('passwd', 'new password', 'new password')
    end

    assert_nothing_raised do
      user.save
    end
  end

  def test_transaction
    user = Wiki::User.create('otto', 'passwd', 'passwd', 'mail@otto.com')

    assert_raise Wiki::MessageError do
      user.transaction do |u|
        u.email = 'invalid'
        u.save
      end
    end

    assert_equal 'mail@otto.com', user.email
  end
end

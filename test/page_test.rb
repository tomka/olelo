require 'spec_setup'
require 'wiki/user'

describe 'Wiki::Page' do
  before(:each) { create_repository }
  after(:each) { destroy_repository }

  it 'should have correct path' do
    Wiki::Page.new(@repo, '/path/name.ext').path == 'path/name.ext'
  end

  it 'should have correct extension' do
    Wiki::Page.new(@repo, '/path/name.tar.gz').path == 'tar.gz'
  end

  it 'write content' do
    page = Wiki::Page.new(@repo, 'test')
    page.should.be.new
    page.should.be.modified
    page.content.should == nil
    page.write('old content', "message1\ntext", Wiki::User.new('Author1', 'author1@localhorst'))

    page.content.should == 'old content'
    page.should.not.be.new
    page.should.not.be.modified

    page.commit.message.should == "message1 text"
    page.commit.author.name.should == 'Author1'
    page.commit.author.email.should == 'author1@localhorst'

    page.content = 'new content'
    page.should.not.be.new
    page.should.be.modified
    page.content.should == 'new content'
    page.write('new content', 'message2', Wiki::User.new('Author2', 'author2@localhorst'))

    page.commit.message.should == 'message2'
    page.commit.author.name.should == 'Author2'
    page.commit.author.email.should == 'author2@localhorst'

    page = Wiki::Page.find!(@repo, 'test')
    page.should.not.be.new
    page.content.should == 'new content'

    page.commit.message.should == 'message2'
    page.commit.author.name.should == 'Author2'
    page.commit.author.email.should == 'author2@localhorst'
  end

  it 'fail on duplicates' do
    page = Wiki::Page.new(@repo, 'test')
    page.write('content', 'message', Wiki::User.new('Author', 'author@localhorst'))

    page = Wiki::Page.new(@repo, 'test')
    assert_raise Wiki::MultiError do
      page.write('content', 'message', Wiki::User.new('Author', 'author@localhorst'))
    end
  end
end

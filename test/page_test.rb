require 'spec_setup'
require 'wiki/user'

describe 'Wiki::Page' do
  before { create_repository }
  after { destroy_repository }

  it 'should have correct path' do
    Wiki::Page.new(@repo, '/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'should have correct extension' do
    Wiki::Page.new(@repo, '/path/name.tar.gz').extension.should.equal 'tar.gz'
  end

  it 'write content' do
    page = Wiki::Page.new(@repo, 'test')
    page.should.be.new
    page.should.be.modified
    page.content.should.equal nil
    page.write('old content', "message1\ntext", Wiki::User.new('Author1', 'author1@localhorst'))

    page.content.should.equal 'old content'
    page.should.not.be.new
    page.should.not.be.modified

    page.commit.message.should.equal "message1 text"
    page.commit.author.name.should.equal 'Author1'
    page.commit.author.email.should.equal 'author1@localhorst'

    page.content = 'new content'
    page.should.not.be.new
    page.should.be.modified
    page.content.should.equal 'new content'
    page.write('new content', 'message2', Wiki::User.new('Author2', 'author2@localhorst'))

    page.commit.message.should.equal 'message2'
    page.commit.author.name.should.equal 'Author2'
    page.commit.author.email.should.equal 'author2@localhorst'

    page = Wiki::Page.find!(@repo, 'test')
    page.should.not.be.new
    page.content.should.equal 'new content'

    page.commit.message.should.equal 'message2'
    page.commit.author.name.should.equal 'Author2'
    page.commit.author.email.should.equal 'author2@localhorst'
  end

  it 'fail on duplicates' do
    page = Wiki::Page.new(@repo, 'test')
    page.write('content', 'message', Wiki::User.new('Author', 'author@localhorst'))

    page = Wiki::Page.new(@repo, 'test')
    lambda do
      page.write('content', 'message', Wiki::User.new('Author', 'author@localhorst'))
    end.should.raise Wiki::MultiError
  end
end

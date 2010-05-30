require 'helper'

describe 'Wiki::Page' do
  before { create_repository }
  after { destroy_repository }

  it 'should have correct path' do
    Wiki::Page.new('/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'should have correct extension' do
    Wiki::Page.new('/path/name.tar.gz').extension.should.equal 'tar.gz'
  end

  it 'write content' do
    page = Wiki::Page.new('test')
    page.should.be.new
    page.should.be.modified
    page.content.should.equal nil
    Wiki::Page.transaction "comment1\ntext", Wiki::User.new('Author1', 'author1@localhorst') do
      page.write('old content')
    end

    page.content.should.equal 'old content'
    page.should.not.be.new
    page.should.not.be.modified

    page.tree_version.comment.should.equal "comment1\ntext"
    page.tree_version.author.name.should.equal 'Author1'
    page.tree_version.author.email.should.equal 'author1@localhorst'

    page.content = 'new content'
    page.should.not.be.new
    page.should.be.modified
    page.content.should.equal 'new content'
    Wiki::Page.transaction 'comment2', Wiki::User.new('Author2', 'author2@localhorst') do
      page.write('new content')
    end

    page.tree_version.comment.should.equal 'comment2'
    page.tree_version.author.name.should.equal 'Author2'
    page.tree_version.author.email.should.equal 'author2@localhorst'

    page = Wiki::Page.find!('test')
    page.should.not.be.new
    page.content.should.equal 'new content'

    page.tree_version.comment.should.equal 'comment2'
    page.tree_version.author.name.should.equal 'Author2'
    page.tree_version.author.email.should.equal 'author2@localhorst'
  end

  it 'fail on duplicates' do
    page = Wiki::Page.new('test')
    Wiki::Page.transaction 'comment', Wiki::User.new('Author', 'author@localhorst') do
      page.write('content')
    end

    page = Wiki::Page.new('test')
    lambda do
      Wiki::Page.transaction 'comment', Wiki::User.new('Author', 'author@localhorst') do
        page.write('content')
      end
    end.should.raise RuntimeError
  end
end

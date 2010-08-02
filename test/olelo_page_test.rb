require 'helper'

describe 'Olelo::Page' do
  before { create_repository }
  after { destroy_repository }

  it 'should have correct path' do
    Olelo::Page.new('/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'should have correct extension' do
    Olelo::Page.new('/path/name.tar.gz').extension.should.equal 'tar.gz'
  end

  it 'write content' do
    page = Olelo::Page.new('test')
    page.should.be.new
    page.should.be.modified
    page.content.should.equal nil
    Olelo::Page.transaction "comment1\ntext", Olelo::User.new('Author1', 'author1@localhorst') do
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
    Olelo::Page.transaction 'comment2', Olelo::User.new('Author2', 'author2@localhorst') do
      page.write('new content')
    end

    page.tree_version.comment.should.equal 'comment2'
    page.tree_version.author.name.should.equal 'Author2'
    page.tree_version.author.email.should.equal 'author2@localhorst'

    page = Olelo::Page.find!('test')
    page.should.not.be.new
    page.content.should.equal 'new content'

    page.tree_version.comment.should.equal 'comment2'
    page.tree_version.author.name.should.equal 'Author2'
    page.tree_version.author.email.should.equal 'author2@localhorst'
  end

  it 'fail on duplicates' do
    page = Olelo::Page.new('test')
    Olelo::Page.transaction 'comment', Olelo::User.new('Author', 'author@localhorst') do
      page.write('content')
    end

    page = Olelo::Page.new('test')
    lambda do
      Olelo::Page.transaction 'comment', Olelo::User.new('Author', 'author@localhorst') do
        page.write('content')
      end
    end.should.raise RuntimeError
  end
end

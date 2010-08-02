require 'helper'

describe 'Olelo::Resource' do
  before { create_repository }
  after { destroy_repository }

  it 'check for path validity' do
    lambda do
      Olelo::Resource.find(' spaces ')
    end.should.raise RuntimeError
    Olelo::Resource.find('spaces in the path').should.equal nil
  end

  it 'should have no root before the first page is created' do
    Olelo::Resource.find('').should.equal nil
    create_page('Home')
    Olelo::Resource.find('').should.be.an.instance_of Olelo::Tree
  end

  it 'find root with correct type' do
    create_page('Home')

    Olelo::Resource.find('').should.be.an.instance_of Olelo::Tree
    Olelo::Tree.find('').should.be.an.instance_of Olelo::Tree
    Olelo::Page.find('').should.equal nil

    Olelo::Resource.find('/').should.be.an.instance_of Olelo::Tree
    Olelo::Tree.find('/').should.be.an.instance_of Olelo::Tree
    Olelo::Page.find('/').should.equal nil

    Olelo::Resource.find('/root').should.be.an.instance_of Olelo::Tree
    Olelo::Tree.find('/root').should.be.an.instance_of Olelo::Tree
    Olelo::Page.find('/root').should.equal nil

    Olelo::Resource.find('Home').should.be.an.instance_of Olelo::Page
    Olelo::Tree.find('Home').should.equal nil
    Olelo::Page.find('Home').should.be.an.instance_of Olelo::Page
  end

  it 'find or raise' do
    Olelo::Resource.find!('').should.be.an.instance_of Olelo::Tree
    Olelo::Tree.find!('').should.be.an.instance_of Olelo::Tree
    lambda do
      Olelo::Page.find!('/root')
    end.should.raise Olelo::ObjectNotFound

    Olelo::Resource.find('Home').should.be.an.instance_of Olelo::Page
    Olelo::Page.find('Home').should.be.an.instance_of Olelo::Page
    lambda do
      Olelo::Tree.find!('/Home')
    end.should.raise Olelo::ObjectNotFound

    lambda do
      Olelo::Resource.find!('/foo')
    end.should.raise Olelo::ObjectNotFound

    lambda do
      Olelo::Page.find!('/foo')
    end.should.raise Olelo::ObjectNotFound

    lambda do
      Olelo::Tree.find!('/foo')
    end.should.raise Olelo::ObjectNotFound
  end

  it 'should be new' do
    create_page('Home')
    Olelo::Page.find('Home').should.not.be.new
    Olelo::Tree.find('').should.not.be.new
    Olelo::Page.new('new').should.be.new
    Olelo::Tree.new('new').should.be.new
  end

  it 'has type' do
    Olelo::Page.find('Home').should.be.page
    Olelo::Tree.find('').should.be.tree
  end

  it 'has name' do
    Olelo::Resource.new('/path/name.ext').name.should.equal 'name.ext'
  end

  it 'has path' do
    Olelo::Resource.new('/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'has safe name' do
    Olelo::Resource.new('0 1 2 3 4 5').safe_name.should.equal '0_1_2_3_4_5'
  end
end

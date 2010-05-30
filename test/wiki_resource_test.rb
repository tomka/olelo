require 'helper'

describe 'Wiki::Resource' do
  before { create_repository }
  after { destroy_repository }

  it 'check for path validity' do
    lambda do
      Wiki::Resource.find(' spaces ')
    end.should.raise RuntimeError
    Wiki::Resource.find('spaces in the path').should.equal nil
  end

  it 'find root with correct type' do
    Wiki::Resource.find('').should.equal nil

    create_page('Home')

    Wiki::Resource.find('').should.be.an.instance_of Wiki::Tree
    Wiki::Tree.find('').should.be.an.instance_of Wiki::Tree
    Wiki::Page.find('').should.equal nil

    Wiki::Resource.find('/').should.be.an.instance_of Wiki::Tree
    Wiki::Tree.find('/').should.be.an.instance_of Wiki::Tree
    Wiki::Page.find('/').should.equal nil

    Wiki::Resource.find('/root').should.be.an.instance_of Wiki::Tree
    Wiki::Tree.find('/root').should.be.an.instance_of Wiki::Tree
    Wiki::Page.find('/root').should.equal nil

    Wiki::Resource.find('Home').should.be.an.instance_of Wiki::Page
    Wiki::Tree.find('Home').should.equal nil
    Wiki::Page.find('Home').should.be.an.instance_of Wiki::Page
  end

  it 'find or raise' do
    Wiki::Resource.find!('').should.be.an.instance_of Wiki::Tree
    Wiki::Tree.find!('').should.be.an.instance_of Wiki::Tree
    lambda do
      Wiki::Page.find!('/root')
    end.should.raise Wiki::ObjectNotFound

    Wiki::Resource.find('Home').should.be.an.instance_of Wiki::Page
    Wiki::Page.find('Home').should.be.an.instance_of Wiki::Page
    lambda do
      Wiki::Tree.find!('/Home')
    end.should.raise Wiki::ObjectNotFound

    lambda do
      Wiki::Resource.find!('/foo')
    end.should.raise Wiki::ObjectNotFound

    lambda do
      Wiki::Page.find!('/foo')
    end.should.raise Wiki::ObjectNotFound

    lambda do
      Wiki::Tree.find!('/foo')
    end.should.raise Wiki::ObjectNotFound
  end

  it 'should be new' do
    create_page('Home')
    Wiki::Page.find('Home').should.not.be.new
    Wiki::Tree.find('').should.not.be.new
    Wiki::Page.new('new').should.be.new
    Wiki::Tree.new('new').should.be.new
  end

  it 'have type' do
    Wiki::Page.find('Home').should.be.page
    Wiki::Tree.find('').should.be.tree
  end

  it 'have name' do
    Wiki::Resource.new('/path/name.ext').name.should.equal 'name.ext'
  end

  it 'have title' do
    Wiki::Resource.new('/path/name.ext').title.should.equal 'name.ext'
  end

  it 'have path' do
    Wiki::Resource.new('/path/name.ext').path.should.equal 'path/name.ext'
  end

  it 'have safe name' do
    Wiki::Resource.new('0 1 2 3 4 5').safe_name.should.equal '0_1_2_3_4_5'
  end
end

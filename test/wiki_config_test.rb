require 'helper'

describe 'Wiki::Config' do
  it 'should have #set and #[]' do
    config = Wiki::Config.new
    config.set('a.b.c', 42)
    config['a.b.c'].should.equal 42
  end

  it 'should generate accessors' do
    config = Wiki::Config.new

    config.set('a.b.c', 42)
    config.a.b.c.should.equal 42

    config.set(:x, 'y.z' => 43)
    config.x.y.z.should.equal 43

    config.update(:n => { :m => 44 })
    config.n.m.should.equal 44
  end

  it 'should be enumerable' do
    config = Wiki::Config.new
    config.set('a.x.y', 42)
    config.set('b.x.y', 43)
    config.each do |key, child|
      key.should.be.instance_of String
      child.should.be.instance_of Wiki::Config
      child.x.y.should.be.instance_of Fixnum
    end
  end

  it 'should raise NameError' do
    lambda do
      Wiki::Config.new.not.existing
    end.should.raise NameError
  end
end

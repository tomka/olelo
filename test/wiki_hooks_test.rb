require 'wiki/extensions'
require 'wiki/hooks'

describe 'Wiki::Hooks' do
  before do
    @hooks_test = Class.new do
      include Wiki::Hooks
    end
  end

  after do
    @hooks_test = nil
  end

  it 'should provide #hook' do
    @hooks_test.should.respond_to :hook
  end

  it 'should provide #before' do
    @hooks_test.should.respond_to :before
  end

  it 'should provide #after' do
    @hooks_test.should.respond_to :after
  end

  it 'should invoke hooks' do
    hooks_test = @hooks_test
    @hooks_test.hook(:ping) do |a, b|
      self.should.be.instance_of hooks_test
      a.should.equal 1
      b.should.equal 2
      :hook1
    end
    @hooks_test.hook(:ping) do |a, b|
      :hook2
    end
    result = @hooks_test.new.invoke_hook(:ping, 1, 2)
    result.should.be.instance_of Wiki::Hooks::Result
    result.should.equal [:hook1, :hook2]
  end

  it 'should invoke before and after hooks' do
    hooks_test = @hooks_test
    @hooks_test.before(:action) do |a, b|
      self.should.be.instance_of hooks_test
      a.should.equal 1
      b.should.equal 2
      :action_before1
    end
    @hooks_test.before(:action) do |a, b|
      :action_before2
    end
    @hooks_test.after(:action) do |a, b|
      :action_after
    end
    @hooks_test.hook(:action) do |a, b|
      :not_called
    end
    result = @hooks_test.new.with_hooks(:action, 1, 2) do
      :action
    end
    result.should.be.instance_of Wiki::Hooks::Result
    result.should.equal [:action_before1, :action_before2, :action, :action_after]
  end

  it 'should have hook priority' do
    @hooks_test.hook(:ping, 0) { :hook1 }
    @hooks_test.hook(:ping, 1) { :hook2 }
    @hooks_test.new.invoke_hook(:ping).should.equal [:hook2, :hook1]
  end
end

describe 'Wiki::Hooks::Result' do
  it 'should be an array' do
    Wiki::Hooks::Result.new.should.equal []
  end

  it 'should have #to_s' do
    result = Wiki::Hooks::Result.new
    result << :a << :b
    result.to_s.should.equal "ab"
  end
end

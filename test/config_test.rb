require 'spec_setup'
require 'wiki/config'

describe 'Wiki::Config' do
  it 'should set properties' do
    config = Wiki::Config.new
    config.answer = 42
    config.answer.should == 42

    config.answer = 10
    config.answer.should == 10
  end
end

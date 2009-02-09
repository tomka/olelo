require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default Task'
task :default => :test

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.test_files = FileList['test/test_*.rb']
end

desc 'Remove wiki folder'
task :clean do |t|
  FileUtils.rm_rf '.wiki'
end

#require 'spec/rake/spectask'
#Spec::Rake::SpecTask.new do |t|
#  t.libs = [File.expand_path(Dir.pwd + '/../creole/lib'), File.expand_path(Dir.pwd + '/../ruby-git/lib')] 
#  t.spec_files = FileList['*_spec.rb']
#end

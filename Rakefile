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

desc 'Generate AkaPortal documentation'
Rake::RDocTask.new(:doc) { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'Git-Wiki Documentation'
  rdoc.options << '--line-numbers' << '--inline-source' << '--diagram'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('**/*.rb')
}

#require 'spec/rake/spectask'
#Spec::Rake::SpecTask.new do |t|
#  t.libs = [File.expand_path(Dir.pwd + '/../creole/lib'), File.expand_path(Dir.pwd + '/../ruby-git/lib')] 
#  t.spec_files = FileList['*_spec.rb']
#end

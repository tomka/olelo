require 'rubygems'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |t|
  t.libs = [File.expand_path(Dir.pwd + '/../creole/lib'), File.expand_path(Dir.pwd + '/../ruby-git/lib')] 
  t.spec_files = FileList['*_spec.rb']
end

desc "Clean"
task :clean do |t|
  `rm -rf data`
end

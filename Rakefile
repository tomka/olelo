require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [:test, :spec]

Rake::TestTask.new(:test) do |t|
  t.warning = true
  t.test_files = FileList['test/test_*.rb']
end

Rake::TestTask.new(:spec) do |t|
  t.warning = false # Sinatra warnings
  t.test_files = FileList['test/spec_*.rb']
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


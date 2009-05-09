require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rcov/rcovtask'

task :default => ['test:unit','test:spec','test:coverage']

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test' << 'lib'
    t.warning = true
    t.test_files = FileList['test/test_*.rb']
  end

  Rcov::RcovTask.new(:coverage) do |t|
    t.rcov_opts << '--exclude' << '/gems/,/ruby-git\/lib/'
    t.libs << 'test' << 'lib'
    t.warning = false
    t.verbose = true
    t.test_files = FileList['test/test_*.rb','test/spec_*.rb']
  end

  Rake::TestTask.new(:spec) do |t|
    t.libs << 'test' << 'lib'
    t.warning = false
    t.test_files = FileList['test/spec_*.rb']
  end
end

desc 'Cleanup'
task :clean do |t|
  FileUtils.rm_rf 'doc'
  FileUtils.rm_rf 'coverage'
  FileUtils.rm_rf '.wiki/cache'
  FileUtils.rm_rf '.wiki/log'
end

desc 'Remove wiki folder'
task 'clean:all' => :clean do |t|
  FileUtils.rm_rf '.wiki'
end

desc 'Generate documentation'
Rake::RDocTask.new(:doc) { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'Git-Wiki Documentation'
  rdoc.options << '--line-numbers' << '--inline-source' << '--diagram'
  rdoc.options << '--charset' << 'utf-8'
  rdoc.rdoc_files.include('**/*.rb')
}

namespace('notes') do
  task('todo')      do; system('ack TODO');      end
  task('fixme')     do; system('ack FIXME');     end
  task('hack')      do; system('ack HACK');      end
  task('warning')   do; system('ack WARNING');   end
  task('important') do; system('ack IMPORTANT'); end
end

desc 'Show annotations'
task('notes' => %w(notes:todo notes:fixme notes:hack notes:warning notes:important))

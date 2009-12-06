require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => %w(test:unit test:spec test:coverage)

desc('Shrink JS files')
task :script => %w(static/script.js plugins/treeview/script.js)

desc('Compile CSS files')
task :css => %w(static/themes/blue/style.css plugins/treeview/treeview.css plugins/misc/pygments.css plugins/engine/gallery/gallery.css)

def shrink_js(t)
  sh "cat #{t.prerequisites.sort.join(' ')} | java -jar tools/yuicompressor*.jar --type js -v /dev/stdin > #{t.name}"
  #sh "java -jar tools/compiler.jar --compilation_level SIMPLE_OPTIMIZATIONS #{t.prerequisites.sort.map {|x| "--js #{x}" }.join(' ')} > #{t.name}"
end

def sass(file)
  gem 'haml', '>= 0'
  require 'sass'
  engine = Sass::Engine.new(File.read(file), :style => :compressed, :load_paths => [File.dirname(file)], :cache => false)
  engine.render
end

def spew(file, content)
  File.open(file, 'w') {|f| f.write(content) }
end

file 'plugins/misc/pygments.sass' do
  sh "pygmentize -S default -f html -a .highlight | css2sass > plugins/misc/pygments.sass"
end

file('static/themes/blue/style.css' => Dir.glob('static/themes/blue/*.sass') + Dir.glob('static/themes/lib/*.sass')) do |t|
  puts "Creating #{t.name}..."
  content = "@media screen{#{sass(t.name.gsub('style.css', 'screen.sass'))}}@media print{#{sass(t.name.gsub('style.css', 'print.sass'))}}"
  spew(t.name, content)
end

rule '.css' => ['.sass'] do |t|
  puts "Creating #{t.name}..."
  spew(t.name, sass(t.source))
end

file('static/script.js' => Dir.glob('static/script/*.js')) { |t| shrink_js(t) }
file('plugins/treeview/script.js' => Dir.glob('plugins/treeview/script/*.js')) {|t| shrink_js(t) }

namespace :test do
  Rake::TestTask.new(:unit) do |t|
    t.libs << 'test' << 'lib'
    Dir[::File.join('deps', '*', 'lib')].each {|x| t.libs << x }
    t.warning = true
    t.test_files = FileList['test/test_*.rb']
  end

  #require 'rcov/rcovtask'
  #Rcov::RcovTask.new(:coverage) do |t|
  #  t.rcov_opts << '--exclude' << '/gems/,/ruby-git\/lib/'
  #  t.libs << 'test' << 'lib'
  #  t.warning = false
  #  t.verbose = true
  #  t.test_files = FileList['test/test_*.rb','test/spec_*.rb']
  #end

  Rake::TestTask.new(:spec) do |t|
    t.libs << 'test' << 'lib'
    Dir[::File.join('deps', '*', 'lib')].each {|x| t.libs << x }
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

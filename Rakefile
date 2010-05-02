require 'rubygems'
require 'rake'

task :default => %w(test:spec)

def shrink_js(t)
  sh "cat #{t.prerequisites.sort.join(' ')} | java -jar tools/yuicompressor*.jar --type js -v /dev/stdin > #{t.name}"
  #sh "java -jar tools/compiler.jar --compilation_level ADVANCED_OPTIMIZATIONS #{t.prerequisites.sort.map {|x| "--js #{x}" }.join(' ')} > #{t.name}"
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

file 'plugins/utils/pygments.sass' do
  sh "pygmentize -S default -f html -a .highlight | css2sass > plugins/utils/pygments.sass"
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
file('plugins/engine/gallery/script.js' => Dir.glob('plugins/engine/gallery/script/*.js')) {|t| shrink_js(t) }

namespace :gen do
  desc('Shrink JS files')
  task :js => %w(static/script.js plugins/treeview/script.js plugins/engine/gallery/script.js)

  desc('Compile CSS files')
  task :css => %w(static/themes/blue/style.css plugins/treeview/treeview.css plugins/utils/pygments.css plugins/engine/gallery/gallery.css)
end

namespace :test do
  desc 'Run tests with bacon'
  task :spec => FileList['test/*_test.rb'] do |t|
    sh "bacon -q -Ilib:test #{t.prerequisites.join(' ')}"
  end

  desc 'Generate test coverage report'
  task :rcov => FileList['test/*_test.rb'] do |t|
    sh "rcov -Ilib:test #{t.prerequisites.join(' ')}"
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
task :doc => 'doc/api/index.html'
file 'doc/api/index.html' => FileList['**/*.rb'] do |f|
  sh "rdoc -o doc/api --title 'Git-Wiki Documentation' --inline-source --format=html #{f.prerequisites.join(' ')}"
end

namespace('notes') do
  task('todo')      do; system('ack TODO');      end
  task('fixme')     do; system('ack FIXME');     end
  task('hack')      do; system('ack HACK');      end
  task('warning')   do; system('ack WARNING');   end
  task('important') do; system('ack IMPORTANT'); end
end

desc 'Show annotations'
task('notes' => %w(notes:todo notes:fixme notes:hack notes:warning notes:important))

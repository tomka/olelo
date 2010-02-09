author       'Daniel Mendler'
description  'LaTeX/Graphviz image renderer'
dependencies 'gem:imaginator'
autoload 'Imaginator', 'imaginator'

class Wiki::App
  assets 'imaginator_failed.png'

  get '/_/misc/imaginator/:name', :patterns => {:name => '[\w\.]+'} do
    begin
      send_file Plugin['misc/imaginator'].imaginator.result(params[:name])
    rescue Exception => ex
      logger.error ex
      redirect '/_/misc/imaginator_failed.png'
    end
  end
end

def imaginator
  @imaginator ||= Imaginator.new("drbunix://#{Config.cache}/imaginator.sock", File.join(Config.cache, 'imaginator')) do |server|
    server.add_renderer(:math,  Imaginator::LaTeX.new)
    server.add_renderer(:dot,   Imaginator::Graphviz.new(:cmd => 'dot'))
    server.add_renderer(:neato, Imaginator::Graphviz.new(:cmd => 'neato'))
    server.add_renderer(:twopi, Imaginator::Graphviz.new(:cmd => 'twopi'))
    server.add_renderer(:circo, Imaginator::Graphviz.new(:cmd => 'circo'))
    server.add_renderer(:fdp,   Imaginator::Graphviz.new(:cmd => 'fdp'))
  end
end

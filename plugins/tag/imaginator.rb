author       'Daniel Mendler'
description  'LaTeX/Graphviz support'
dependencies 'filter/tag', 'gem:imaginator'
require      'imaginator'

class Wiki::App
  static_files 'imaginator_failed.png'

  def self.imaginator
    @imaginator ||= Imaginator.new("drbunix://#{Config.cache}/imaginator.sock", File.join(Config.cache, 'imaginator')) do |server|
      server.add_renderer(:math,  Imaginator::LaTeX.new)
      server.add_renderer(:dot,   Imaginator::Graphviz.new(:cmd => 'dot'))
      server.add_renderer(:neato, Imaginator::Graphviz.new(:cmd => 'neato'))
      server.add_renderer(:twopi, Imaginator::Graphviz.new(:cmd => 'twopi'))
      server.add_renderer(:circo, Imaginator::Graphviz.new(:cmd => 'circo'))
      server.add_renderer(:fdp,   Imaginator::Graphviz.new(:cmd => 'fdp'))
    end
  end

  get '/sys/tag/imaginator/:name', :patterns => {:name => '[\w\.]+'} do
    begin
      send_file App.imaginator.result(params[:name])
    rescue Exception => ex
      @logger.error ex
      redirect '/sys/tag/imaginator_failed.png'
    end
  end
end

def define_tag(type)
  Tag.define type do |context, attrs, content|
    raise(RuntimeError, "Limits exceeded") if content.size > 10240
    name = App.imaginator.enqueue(type, content)
    alt = escape_html content.truncate(30).gsub(/\s+/, ' ')
    "<img src=\"/sys/tag/imaginator/#{name}\" alt=\"#{alt}\"/>"
  end
end

define_tag :dot
define_tag :neato
define_tag :twopi
define_tag :circo
define_tag :fdp

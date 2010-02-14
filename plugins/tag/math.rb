author       'Daniel Mendler'
description  'LaTeX rendering (math tags)'
dependencies 'filter/tag'

class Renderer
  def initialize
    @loaded = false
  end

  def init
    @loaded ||= load rescue false
  end

  class << self
    attr_accessor :registry

    def get_first(renderers)
      renderers.each do |r|
        r = get(r)
        return r if r
      end
    end

    def get(name)
      renderer = registry[name] || raise(RuntimeError, "Renderer #{name} not found")
      if Array === renderer
        get_first(renderer)
      elsif String === renderer
        get(renderer)
      elsif renderer.init
        renderer
      end
    end

    def choose(name)
      get(name) || get_first(registry.keys) || raise(RuntimeError, 'No renderer found')
    end
  end
end

class ImaginatorRenderer < Renderer
  def load
    Plugin.load('utils/imaginator')
  end

  def render(code, display)
    name = Plugin['utils/imaginator'].imaginator.enqueue('math', code)
    %{<img src="/_/utils/imaginator/#{name}" alt="#{Wiki.html_escape code}" class="math #{display}"/>}
  end
end

class RitexRenderer < Renderer
  def load
    gem 'ritex', '>= 0'
    require 'ritex'
    true
  end

  def render(code, display)
    Ritex::Parser.new.parse(code)
  end
end

class ItexRenderer < Renderer
  def load
    require 'open3'
    `itex2MML --version`
  end

  def render(code, display)
    Open3.popen3("itex2MML --#{display == 'block' ? 'display' : 'inline'}") do |stdin, stdout, stderr|
      stdin << code.strip
      stdin.close
      stdout.read
    end
  end
end

class BlahtexMLRenderer < Renderer
  def load
    require 'open3'
    `blahtex`
  end

  def render(code, display)
    content = Open3.popen3('blahtex --mathml') do |stdin, stdout, stderr|
      stdin << code.strip
      stdin.close
      stdout.read
    end
    content =~ %r{<mathml>(.*)</mathml>}m
    '<mathml xmlns="http://www.w3.org/1998/Math/MathML" display="' + display + '">' + $1.to_s + '</mathml>'
  end
end

class BlahtexImageRenderer < Renderer
  def load
    require 'open3'
    `blahtex`
  end

  def directory
    @directory ||= begin
                     dir = File.join(Config.cache, 'blahtex')
                     FileUtils.mkdir_p dir, :mode => 0755
                     dir
                   end
  end

  def render(code, display)
    content = Open3.popen3("blahtex --png --png-directory '#{directory}'") do |stdin, stdout, stderr|
      stdin << code.strip
      stdin.close
      stdout.read
    end
    content =~ %r{<md5>(.*)</md5>}m
    %{<img src="/_/tag/math/blahtex/#{$1}.png" alt="#{Wiki.html_escape code}" class="math #{display}"/>}
  end
end

Renderer.registry = {
  'imaginator'   => ImaginatorRenderer.new,
  'itex'         => ItexRenderer.new,
  'ritex'        => RitexRenderer.new,
  'blahtexml'    => BlahtexMLRenderer.new,
  'blahteximage' => BlahtexImageRenderer.new,
  'image'        => %w(imaginator blahteximage),
  'mathml'       => %w(blahtexml itex ritex),
}

Tag.define :math do |context, attrs, code|
  raise(RuntimeError, "Limits exceeded") if code.size > 10240
  mode = attrs['mode'] || context.page.metadata['math'] || 'image'
  Renderer.choose(mode).render(code, attrs['display'] == 'block' ? 'block' : 'inline')
end

class Wiki::App
  get '/_/tag/math/blahtex/:name', :patterns => {:name => '[\w\.]+'} do
    send_file File.join(Renderer.get('blahteximage').directory, params[:name])
  end
end

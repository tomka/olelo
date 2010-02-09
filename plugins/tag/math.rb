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
        r = get_renderer(r)
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
    Plugin.load('misc/imaginator')
  end

  def render(code)
    name = Plugin['misc/imaginator'].imaginator.enqueue('math', code)
    %{<img src="/_/misc/imaginator/#{name}" alt="#{Wiki.html_escape code}"/>}
  end
end

class RitexRenderer < Renderer
  def load
    return false if !Plugin.load('misc/mathml')
    gem 'ritex', '>= 0'
    require 'ritex'
    true
  end

  def render(code)
    MathML.replace_entities Ritex::Parser.new.parse(code)
  end
end

class ItexRenderer < Renderer
  def load
    return false if !Plugin.load('misc/mathml')
    require 'open3'
    `itex2MML --version`
  end

  def render(code)
    output = Open3.popen3('itex2MML --inline') do |stdin, stdout, stderr|
      stdin << code.strip
      stdin.close
      stdout.read
    end
    MathML.replace_entities(output)
  end
end

Renderer.registry = {
  'imaginator' => ImaginatorRenderer.new,
  'itex'       => ItexRenderer.new,
  'ritex'      => RitexRenderer.new,
  'image'      => 'imaginator',
  'mathml'     => %w(itex ritex),
}

Tag.define :math do |context, attrs, code|
  raise(RuntimeError, "Limits exceeded") if code.size > 10240
  mode = attrs['mode'] || context.page.metadata['math'] || 'image'
  type = attrs['type'] == 'block' ? 'block' : 'inline'
  %{<div class="math #{attrs['type']}">#{Renderer.choose(mode).render(code)}</div>}
end

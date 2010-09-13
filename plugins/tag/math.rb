description  'Math tag for LaTeX rendering'
dependencies 'filter/tag'

class Olelo::MathRenderer
  include Util

  def initialize
    @loaded = false
  end

  def init
    @loaded ||= load rescue false
  end

  def load
    true
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
      renderer = registry[name] || raise("Renderer #{name} not found")
      if Array === renderer
        get_first(renderer)
      elsif String === renderer
        get(renderer)
      elsif renderer.init
        renderer
      end
    end

    def choose(name)
      get(name) || get_first(registry.keys) || raise('No renderer found')
    end
  end
end

class RitexRenderer < MathRenderer
  def load
    require 'ritex'
    true
  end

  def render(code, display)
    Ritex::Parser.new.parse(code)
  end
end

class ItexRenderer < MathRenderer
  def load
    `itex2MML --version`
  end

  def render(code, display)
    Shell.itex2MML(display == 'block' ? '--display' : '--inline').run(code.strip)
  end
end

class BlahtexMLRenderer < MathRenderer
  def load
    `blahtex`
  end

  def render(code, display)
    content = Shell.blahtex('--mathml').run(code.strip)
    content =~ %r{<mathml>(.*)</mathml>}m
    '<mathml xmlns="http://www.w3.org/1998/Math/MathML" display="' + display + '">' + $1.to_s + '</mathml>'
  end
end

class BlahtexImageRenderer < MathRenderer
  def load
    `blahtex`
  end

  def directory
    @directory ||= File.join(Config.tmp_path, 'blahtex').tap {|dir| FileUtils.mkdir_p dir, :mode => 0755 }
  end

  def render(code, display)
    content = Shell.blahtex('--png', '--png-directory', directory).run(code.strip)
    content =~ %r{<md5>(.*)</md5>}m
    path = absolute_path "_/tag/math/blahtex/#{$1}.png"
    %{<img src="#{escape_html path}" alt="#{escape_html code}" class="math #{display}"/>}
  end
end

class GoogleRenderer < MathRenderer
  def render(code, display)
    %{<img src="http://chart.apis.google.com/chart?cht=tx&amp;chl=#{escape code}" alt="#{escape_html code}" class="math #{display}"/>}
  end
end

MathRenderer.registry = {
  'itex'         => ItexRenderer.new,
  'ritex'        => RitexRenderer.new,
  'blahtexml'    => BlahtexMLRenderer.new,
  'blahteximage' => BlahtexImageRenderer.new,
  'google'       => GoogleRenderer.new,
  'image'        => %w(google blahteximage),
  'mathml'       => %w(blahtexml itex ritex),
}

Tag.define :math do |context, attrs, code|
  raise('Limits exceeded') if code.size > 10240
  mode = attrs['mode'] || context.page.attributes['math'] || 'image'
  MathRenderer.choose(mode).render(code, attrs['display'] == 'block' ? 'block' : 'inline')
end

class Olelo::Application
  attribute_editor do
    attribute :math, MathRenderer.registry.keys
  end

  get '/_/tag/math/blahtex/:name', :name => /[\w\.]+/ do
    begin
      file = File.join(MathRenderer.get('blahteximage').directory, params[:name])
      response['Content-Type'] = 'image/png'
      response['Content-Length'] ||= File.stat(file).size.to_s
      halt BlockFile.open(file, 'rb')
    rescue => ex
      ImageMagick.label(ex.message)
    end
  end
end

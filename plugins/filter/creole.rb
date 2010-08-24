description  'Creole wiki text filter'
dependencies 'engine/filter'
require      'creole'

class OleloCreoleParser < Creole
  include PageHelper
  include Util

  def make_image(path, title)
    args = title.to_s.split('|')
    if path =~ %r{^(\w+)://}
      image_path = page_path = path
    else
      geometry = args.grep(/(\d+x)|(x\d+)|(\d+%)/).first
      opts = {:output => 'image'}
      if geometry
        args.delete(geometry)
        opts[:geometry] = geometry
      end
      image_path = absolute_path(path, opts)
      page_path = absolute_path(path)
    end
    image_path = escape_html(image_path)
    page_path = escape_html(page_path)
    nolink = args.delete('nolink')
    box = args.delete('box')
    alt = escape_html(args[0] ? args[0] : path)
    if nolink
      %{<img src="#{image_path}" alt="#{alt}"/>}
    elsif box
      caption = args[0] ? %{<span class="caption">#{escape_html args[0]}</span>} : ''
      %{<span class="img"><a href="#{page_path}"><img src="#{image_path}" alt="#{alt}"/>#{caption}</a></span>}
    else
      %{<a href="#{page_path}" class="img"><img src="#{image_path}" alt="#{alt}"/></a>}
    end
  end
end

Filter.create :creole do |context, content|
  OleloCreoleParser.new(content, :extensions => true, :no_escape => true).to_html
end

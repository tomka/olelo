author       'Daniel Mendler'
description  'Creole wiki text filter'
dependencies 'engine/filter'
require      'creole'

class CreoleParser < Creole::CreoleParser
  include Helper

  def initialize(page)
    super()
    @page = page
  end

  def make_local_link(path)
    resource_path(@page, :path => path)
  end

  def make_image(path, title)
    args = title.to_s.split('|')
    image_path, page_path = path, path
    if !args.delete('raw')
      geometry = args.find { |x| x =~ /(\d+x)|(x\d+)|(\d+%)/}
      opts = {:path => path, :output => 'image'}
      if geometry
        args.delete(geometry)
        opts[:geometry] = geometry
      end
      image_path = resource_path(@page, opts)
      page_path = resource_path(@page, :path => path)
    end
    image_path = escape_html(image_path)
    page_path = escape_html(page_path)
    nolink = args.delete('nolink')
    box = args.delete('box')
    alt = args[0] ? " alt=\"#{escape_html args[0]}\"" : ''
    if nolink
      "<img src=\"#{image_path}\"#{alt}/>"
    elsif box
      caption = args[0] ? "<span class=\"caption\">#{escape_html args[0]}</span>" : ''
      "<div class=\"img\"><a href=\"#{page_path}\"><img src=\"#{image_path}\"#{alt}/>#{caption}</a></div>"
    else
      "<a href=\"#{page_path}\" class=\"img\"><img src=\"#{image_path}\"#{alt}/></a>"
    end
  end
end

Filter.create :creole do |content|
  CreoleParser.new(context.page).parse(content)
end

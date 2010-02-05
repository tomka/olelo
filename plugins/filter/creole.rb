author       'Daniel Mendler'
description  'Creole wiki text filter'
dependencies 'engine/filter', 'gem:creole'
autoload 'Creole', 'creole'

Filter.create :creole do |content|
  class ::WikiCreoleParser < Creole
    include PageHelper

    def initialize(page)
      super()
      @page = page
    end

    def make_local_link(path)
      resource_path(@page, :path => path)
    end

    def make_image(path, title)
      args = title.to_s.split('|')
      if path =~ %r{^(http|ftp)://}
        return %{<span class="error">External images are not allowed</span>} if !Config.external_img?
        image_path = path.dup
        page_path = path.dup
      else
        geometry = args.find { |x| x =~ /(\d+x)|(x\d+)|(\d+%)/}
        opts = {:path => path, :output => 'image'}
        if geometry
          args.delete(geometry)
          opts[:geometry] = geometry
        end
        image_path = resource_path(@page, opts)
        page_path = resource_path(@page, :path => path)
      end
      image_path = Wiki.html_escape(image_path)
      page_path = Wiki.html_escape(page_path)
      nolink = args.delete('nolink')
      box = args.delete('box')
      alt = Wiki.html_escape(args[0] ? args[0] : path)
      if nolink
        %{<img src="#{image_path}" alt="#{alt}"/>}
      elsif box
        caption = args[0] ? %{<span class="caption">#{Wiki.html_escape args[0]}</span>} : ''
        %{<span class="img"><a href="#{page_path}"><img src="#{image_path}" alt="#{alt}"/>#{caption}</a></span>}
      else
        %{<a href="#{page_path}" class="img"><img src="#{image_path}" alt="#{alt}"/></a>}
      end
    end
  end

  WikiCreoleParser.new(context.page).parse(content)
end

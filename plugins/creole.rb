require 'creole'

module Wiki
  Mime.add('text/x-creole', %w(creole text), %w(text/plain)) do |io|
    io.read(8) == '#!creole'
  end

  Engine.create(:creole, 1, true) do
    accepts do |page|
      page.mime == 'text/x-creole'
    end

    output do |page|
      creole = Creole::CreoleParser.new
      class<< creole
        include Wiki::Helper
        attr_writer :page
        def make_local_link(path)
          object_path(@page, :path => path)
        end
        def make_image(path, alt)
          image_path = escape_html(object_path(@page, :path => path, :output => :raw))
          page_path = escape_html(object_path(@page, :path => path))
          alt = alt ? " alt=\"#{escape_html alt}\"" : ''
          "<a href=\"#{page_path}\"><img src=\"#{image_path}\"#{alt}/></a>"
        end
      end
      creole.page = page
      content = page.content.sub(/^#!creole\s+/,'')
      fix_punctuation(creole.parse(content))
    end
  end
end

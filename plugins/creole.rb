require 'creole'

Mime.add('text/x-creole', %w(creole text), %w(text/plain))

Wiki::Engine.create(:creole, 1, true) do
  accepts do |page|
    page.mime == 'text/x-creole'
  end

  output do |page|
    creole = Creole::CreoleParser.new
    class << creole
      def make_image_link(url)
        url + '?output=raw'
      end
      def make_link(url)
        escape_url(url).urlpath
      end
    end
    fix_punctuation(creole.parse(page.content))
  end
end

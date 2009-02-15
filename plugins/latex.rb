Wiki::Plugin.define :latex do
  require 'latex_renderer'
  depends_on :creole

  $latex = LatexRenderer.new

  class Wiki::App
    alias page_not_found_without_latex page_not_found

    def page_not_found
      if request.path_info =~ /^\/latex\/(\w+)$/
        content_type 'image/png'
        $latex.result($1)
      else
        page_not_found_without_latex
      end
    end
  end

  Wiki::Engine.extend :creole do
    prepend :filter do |page, content|
      content.gsub!(/<math>(.*?)<\/math>/m) do |match|
        begin
          hash = $latex.render($1)
          "{{latex/#{hash}}}"
        rescue
          $1
        end
      end
      [page, content]
    end
  end
end

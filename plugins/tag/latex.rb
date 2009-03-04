Wiki::Plugin.define 'tag/latex' do
  require 'latex-renderer'
  depends_on 'tag/support'
  load_after 'engine/*'

  latex = LaTeX::AsyncRenderer.new(:debug => Wiki::App.development?)

  Wiki::App.class_eval do
    get '/sys/latex/:hash.png' do
      begin
        name, path, hash = latex.result(params[:hash])
        send_file path
      rescue Exception => ex
        @logger.error ex
        redirect '/sys/images/latex_failed.png'
      end
    end
  end

  Wiki::Engine.enhance :creole, :textile, :markdown, :maruku do
    define_tag(:math) do |page,elem|
      name, path, hash = latex.render(elem.inner_text)
      "<img src=\"/sys/latex/#{name}\" alt=\"#{escape_html elem.inner_text}\"/>"
    end
  end
end

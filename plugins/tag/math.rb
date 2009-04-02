Wiki::Plugin.define 'tag/math' do
  require 'latex-renderer'
  depends_on 'filter/tag'

  latex = LaTeX::AsyncRenderer.new(:debug => Wiki::App.development?)

  Wiki::App.class_eval do
    get '/sys/latex/:hash.png' do
      begin
        name, path, hash = latex.result(params[:hash])
        send_file path
      rescue Exception => ex
        @logger.error ex
        redirect image_path('latex_failed')
      end
    end
  end

  Wiki::Tag.define :math do |context, attrs, content|
    name, path, hash = latex.render(content)
    "<img src=\"/sys/latex/#{name}\" alt=\"#{escape_html content}\"/>"
  end
end

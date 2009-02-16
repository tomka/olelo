Wiki::Plugin.define 'misc/latex' do
  require 'latex-renderer'
  depends_on 'engine/creole'

  latex = Latex::AsyncRenderer.new(:debug => Wiki::App.development?)

  Wiki::App.class_eval do
    get "/latex/:hash.png" do
      begin
        name, path, hash = latex.result(params[:hash])
        send_file path
      rescue Exception => ex
        @logger.error ex
        redirect '/images/latex-failed.png'
      end
    end
  end

  Wiki::Engine.extend :creole do
    prepend_filter do |page, content|
      content.gsub!(/<math>(.*?)<\/math>/m) do |match|
        begin
          name, path, hash = latex.render($1)
          "{{/latex/#{name}|nolink|raw}}"
        rescue
          $1
        end
      end
      [page, content]
    end
  end
end

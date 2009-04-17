require 'drb'
depends_on 'filter/tag'

URI = 'drbunix://' + File.join(Config.cache, 'imaginator.sock')
Imaginator = DRb::DRbObject.new(nil, URI)

App.class_eval do
  get '/sys/imaginator/:name', :patterns => {:name => '[\w\.]+'} do
    begin
      send_file Imaginator.result(params[:name])
    rescue Exception => ex
      @logger.error ex
      redirect image_path('image_failed')
    end
  end
end

def define_tag(type)
  Tag.define type do |context, attrs, content|
    name = Imaginator.enqueue(type, content)
    alt = escape_html content.truncate(30).gsub(/\s+/, ' ')
    "<img src=\"/sys/imaginator/#{name}\" alt=\"#{alt}\"/>"
  end
end

define_tag :math
define_tag :dot
define_tag :neato
define_tag :twopi
define_tag :circo
define_tag :fdp

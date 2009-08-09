author       'Daniel Mendler'
description  'Basic searching via grep'

class Wiki::App
  get '/search' do
    matches = @repo.grep(params[:pattern], nil, :ignore_case => true)
    @matches = []
    matches.each_pair do |id,lines|
      if id =~ /^.+?:(.+)$/
        @matches << [$1,lines.map {|x| x[1] }.join("\n").truncate(100)]
      end
    end
    haml :grep
  end
end

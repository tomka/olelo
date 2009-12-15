author      'Daniel Mendler'
description 'Basic searching via grep'

class Wiki::App
  get '/search' do
    lines = repository.git_grep('-e', params[:pattern], '-i', repository.branch).split("\n")
    @matches = {}
    lines.each do |line|
      if line =~ /(.*)\:(.*)\:(.*)/
        (@matches[$2] ||= []) << $3
      end
    end
    haml :grep
  end
end

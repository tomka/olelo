author      'Daniel Mendler'
description 'Basic searching via grep'

class Wiki::App
  get '/search' do

    @matches = {}

    repository.git_ls_tree('-r', '--name-only', 'HEAD') do |io|
      while !io.eof?
        line = io.readline
        line = Wiki.backslash_unescape(line)
        if line =~ /#{params[:pattern]}/
            (@matches[line] ||= []) << ''
        end
      end
    end

    repository.git_grep('-z', '-e', params[:pattern], '-i', repository.branch) do |io|
      while !io.eof?
        line = io.readline
        line = Wiki.backslash_unescape(line)
        if line =~ /(.*)\:(.*)\0(.*)/
          (@matches[$2] ||= []) << $3
        end
      end
    end

    haml :grep
  end
end

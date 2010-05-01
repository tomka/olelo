author      'Daniel Mendler'
description 'Basic searching via grep'

class Wiki::Application
  get '/search' do
    matches = {}

    repository.git_ls_tree('-r', '--name-only', 'HEAD') do |io|
      while !io.eof?
        line = repository.set_encoding(io.readline)
	line = Wiki.backslash_unescape(line)
        if line =~ /#{params[:pattern]}/i
          matches[line] ||= ''
        end
      end
    end

    repository.git_grep('-z', '-e', params[:pattern], '-i', repository.branch) do |io|
      while !io.eof?
        line = repository.set_encoding(io.readline)
	line = Wiki.backslash_unescape(line)
        if line =~ /(.*)\:(.*)\0(.*)/
          (matches[$2] ||= '') << $3
        end
      end
    end rescue nil # git-grep returns 1 if nothing is found

    @matches = matches.map {|k, v| [k.urlpath, emphasize(k), emphasize(v)] }
    render :grep
  end

  private

  def emphasize(s)
    Wiki.html_escape(s.truncate(800)).gsub(/(#{params[:pattern]})/i, '<span style="background: #FAA">\1</span>')
  end
end

author      'Daniel Mendler'
description 'Searching via git-grep'

raise 'Git repository required' if Config.repository.type != 'git'

class Wiki::Application
  get '/search' do
    matches = {}

    git = Repository.instance.git

    git.git_ls_tree('-r', '--name-only', 'HEAD') do |io|
      while !io.eof?
        begin
          line = git.set_encoding(io.readline)
          line = unescape_backslash(line)
          if line =~ /#{params[:pattern]}/i
            matches[line] ||= ''
          end
        rescue => ex
          logger.error ex
        end
      end
    end

    git.git_grep('-z', '-i', '-e', params[:pattern], git.branch) do |io|
      while !io.eof?
        begin
          line = git.set_encoding(io.readline)
          line = unescape_backslash(line)
          if line =~ /(.*)\:(.*)\0(.*)/
            (matches[$2] ||= '') << $3
          end
        rescue => ex
          logger.error ex
        end
      end
    end rescue nil # git-grep returns 1 if nothing is found

    @matches = matches.map {|k, v| [k.urlpath, emphasize(k), emphasize(v)] }
    render :grep
  end

  private

  def emphasize(s)
    escape_html(s.truncate(800)).gsub(/(#{params[:pattern]})/i, '<span style="background: #FAA">\1</span>')
  end
end

__END__

@@ grep.haml
- title :search_results.t(:pattern => params[:pattern])
%p= :match.t(:count => @matches.length)
- @matches.each do |path, name, content|
  .match
    %a.name{:href => path}&= name
    .content&= content

require 'wiki/extensions'
require 'wiki/utils'

module Wiki
  # Wiki helper methods which are mainly used in the views
  # TODO: Restructure this a little bit. Separate view
  # from controller helpers maybe.
  module Helper
    include Utils

    def object
      @object || @page || @tree
    end

    def define_block(name, content = nil, &block)
      name = name.to_sym
      @blocks ||= {}
      @blocks[name] = block_given? ? capture_haml(&block) : content
    end

    def include_block(name)
      name = name.to_sym
      @blocks ||= {}
      @blocks[name].to_s
    end

    def footer(content = nil, &block); define_block(:footer, content, &block); end
    def head(content = nil, &block);   define_block(:head, content, &block);   end
    def title(content = nil, &block);  define_block(:title, content, &block);  end

    def menu(*menu)
      define_block :menu, haml(:menu, :layout => false, :locals => { :menu => menu })
    end

    # Cache control for object
    def cache_control(opts)
      return if !App.production?
      etag(opts[:etag]) if opts[:etag]
      last_modified(opts[:last_modified]) if opts[:last_modified]
      if opts[:validate_only]
        response.headers.delete 'ETag'
        response.headers.delete 'Last-Modified'
        return
      end
      mode = opts[:private] ? 'private' : 'public'
      max_age = opts[:max_age] || (opts[:static] ? 86400 : 0)
      response['Cache-Control'] = "#{mode}, max-age=#{max_age}, must-revalidate"
    end

    def format_patch(diff)
      lines = diff.patch.split(/[\n\r]+/)
      html, plus, minus = '', -1, -1
      lines.each do |line|
        if line =~ %r{^diff --git a/(.+) b/(.+)$}
          path = $1
          html << '</tbody></table>' if !html.empty?
          html << "<table class=\"patch\"><thead><tr><th>-</th><th>+</th><th class=\"title\"><a class=\"left\" href=\"#{path.urlpath}\">#{path}</a>"\
               << "<span class=\"right\"><a href=\"#{(path/diff.from).urlpath}\">#{diff.from.truncate(8, '&#8230;')}</a> to "\
               << "<a href=\"#{(path/diff.to).urlpath}\">#{diff.to.truncate(8, '&#8230;')}</a></span></th></tr></thead><tbody>"
          plus, minus = -1, -1
        elsif line =~ /^@@ -(\d+),\d+ \+(\d+)/
          minus = $1.to_i
          plus = $2.to_i
          html << "<tr><td>&#160;</td><td>&#160;</td><td class=\"marker\">#{escape_html line}</td></tr>"
        elsif plus >= 0
          if line[0..0] == '\\'
            html << "<tr><td>&#160;</td><td>&#160;</td><td class=\"code\">#{escape_html line}</td></tr>"
          elsif line[0..0] == '-'
            html << "<tr><td>#{minus}</td><td>&#160;</td><td class=\"code minus\">#{escape_html line}</td></tr>"
            minus += 1
          elsif line[0..0] == '+'
            html << "<tr><td>&#160;</td><td>#{plus}</td><td class=\"code plus\">#{escape_html line}</td></tr>"
            plus += 1
          else
            html << "<tr><td>#{minus}</td><td>#{plus}</td><td class=\"code\">#{escape_html line}</td></tr>"
            minus += 1
            plus += 1
          end
        end
      end
      html << '</tbody></table>' if !html.empty?
      html
    end

    def date(t)
      "<span class=\"date seconds_#{t.to_i}\">#{t.strftime('%d %h %Y %H:%M')}</span>"
    end

    def breadcrumbs(object)
      path = object.respond_to?(:path) ? object.path : ''
      links = ["<a href=\"#{object_path(object, :path => '/root')}\">&#8730;&#175; Root</a>"]
      path.split('/').inject('') {|parent,elem|
        links << "<a href=\"#{object_path(object, :path => parent/elem)}\">#{elem}</a>"
        parent/elem
      }

      result = []
      links.each_with_index {|link,i|
        result << "<li class=\"breadcrumb#{i==0 ? ' first' : ''}#{i==links.size-1 ? ' last' : ''}\">#{link}</li>\n"
      }
      result.join("<li class=\"breadcrumb\">/</li>\n")
    end

    def object_path(object, opts = {})
      sha = opts.delete(:sha) || (object && !object.current? ? object.commit : nil) || ''
      sha = sha.sha if sha.respond_to?(:sha)
      path = opts.delete(:path) || object.path
      path = (path/sha).urlpath
      path << '?' << opts.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&') if !opts.empty?
      path
    end

    def action_path(object, action)
      (object.path/action.to_s).urlpath
    end

    def static_path(name)
      "/static/#{name}"
    end

    def script_path(name)
      static_path "script/#{name}"
    end

    def image_path(name)
      static_path "images/#{name}.png"
    end

    def image(name, opts = {})
      opts[:alt] ||= ''
      attrs = []
      opts.each_pair {|key,value| attrs << "#{key}=\"#{escape_html value}\"" }
      "<img src=\"#{image_path name}\" #{attrs.join(' ')}/>"
    end

    def tab_selected(action)
      action?(action) ? {:class=>'ui-tabs-selected'} : {}
    end

    def show_messages
      if @messages
        out = "<ul>\n"
        @messages.each do |msg|
          out += "  <li class=\"#{msg[0]}\">#{msg[1]}</li>\n"
        end
        out += "</ul>\n"
        return out
      end
      ''
    end

    def message(level, *messages)
      @messages ||= []
      messages.each do |msg|
        @messages << [level, msg]
      end
    end

    def action?(name)
      if params[:action]
        params[:action].downcase == name.to_s
      else
        request.path_info.ends_with? '/' + name.to_s
      end
    end

  end
end

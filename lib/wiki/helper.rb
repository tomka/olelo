require 'wiki/extensions'
require 'wiki/utils'
require 'mimemagic'
require 'cgi'

module Wiki
  # Wiki helper methods which are mainly used in the views
  # TODO: Restructure this a little bit. Separate view
  # from controller helpers maybe.
  module Helper
    lazy_reader(:blocks) { Hash.with_indifferent_access('') }

    def start_timer
      @start_time = Time.now
    end

    def elapsed_time
      ((Time.now - @start_time) * 1000).to_i
    end

    def define_block(name, content = nil, &block)
      blocks[name] = block ? capture_haml(&block) : content
    end

    def include_block(name)
      content_hook(name) { blocks[name] }
    end

    def render_block(name, &block)
      content_hook(name) { capture_haml(&block) }
    end

    def footnote(content = nil, &block); define_block(:footnote, content, &block); end
    def head(content = nil, &block);     define_block(:head, content, &block);     end
    def title(content = nil, &block);    define_block(:title, content, &block);    end

    def menu(*menu)
      define_block :menu, haml(:menu, :layout => false, :locals => { :menu => menu })
    end

    def include_menu
      blocks.include?(:menu) || menu
      include_block(:menu)
    end

    # Access the underlying Rack session.
    def session
      env['rack.session'] ||= {}
    end

    def accepts?(mime)
      env['HTTP_ACCEPT'].to_s.split(',').map(&:strip).include?(mime)
    end

    def content_type(type, params={})
      type = type.to_s
      if params.any?
        params = params.collect { |kv| "%s=%s" % kv }.join(', ')
        response['Content-Type'] = [type, params].join(";")
      else
        response['Content-Type'] = type
      end
    end

    def send_file(file, opts = {})
      content_type(opts[:content_type] || MimeMagic.by_extension(File.extname(file)) || 'application/octet-stream')
      if opts[:disposition] == 'attachment' || opts[:filename]
        response['Content-Disposition'] = 'attachment; filename="%s"' % (opts[:filename] || File.basename(file))
      elsif opts[:disposition] == 'inline'
        response['Content-Disposition'] = 'inline'
      end
      response['Content-Length'] ||= File.stat(file).size.to_s
      halt BlockFile.open(file, 'rb')
    rescue Errno::ENOENT
      raise NotFound
    end

    def no_cache?
      env['HTTP_PRAGMA'] == 'no-cache' || env['HTTP_CACHE_CONTROL'].to_s.include?('no-cache')
    end

    # Cache control for resource
    def cache_control(opts)
      return if !Config.production?

      if opts[:etag]
        value = '"%s"' % opts[:etag]
        response['ETag'] = value if !opts[:validate_only]
        if etags = env['HTTP_IF_NONE_MATCH']
          etags = etags.split(/\s*,\s*/)
          halt(304) if etags.include?(value) || etags.include?('*')
        end
      end

      if opts[:last_modified]
        time = opts[:last_modified]
        time = time.to_time if time.respond_to?(:to_time)
        time = time.httpdate if time.respond_to?(:httpdate)
        response['Last-Modified'] = time if !opts[:validate_only]
        halt(304) if time == request.env['HTTP_IF_MODIFIED_SINCE']
      end

      mode = opts[:private] ? 'private' : 'public'
      max_age = opts[:max_age] || (opts[:static] ? 2592000 : 0)
      response['Cache-Control'] = "#{mode}, max-age=#{max_age}, must-revalidate"
    end

    def no_caching
      response.headers.delete('ETag')
      response.headers.delete('Last-Modified')
      response.headers.delete('Cache-Control')
    end

    def format_patch(patch, from = nil, to = nil)
      lines = patch.split(/[\n\r]+/)
      html, plus, minus, path = '', -1, -1, nil
      lines.each do |line|
        if line =~ %r{^diff --git a/(.+) b/(.+)$}
          path = $1
        elsif line =~ /^\+\+\+ (.*)$/
          html << '</tbody></table>' if !html.empty?
          if path && from && to
            html << %Q{<table class="patch"><thead><tr><th>-</th><th>+</th><th class="title"><a class="left" href="#{path.urlpath}">#{path}</a>
<span class="right"><a href="#{(path/from).urlpath}">#{from.truncate(8, '&#8230;')}</a> to
<a href="#{(path/to).urlpath}">#{to.truncate(8, '&#8230;')}</a></span></th></tr></thead><tbody>}
          else
            html << %Q{<table class="patch"><thead><tr><th>-</th><th>+</th><th class="title">#{$1}</th></tr></thead><tbody>}
          end
          plus, minus = -1, -1
        elsif line =~ /^@@ -(\d+)(,\d+)? \+(\d+)/
          minus = $1.to_i
          plus = $3.to_i
          html << %Q{<tr><td>&#160;</td><td>&#160;</td><td class="marker">#{escape_html line}</td></tr>}
        elsif plus >= 0
          if line[0..0] == '\\'
            html << %Q{<tr><td>&#160;</td><td>&#160;</td><td class="code">#{escape_html line}</td></tr>}
          elsif line[0..0] == '-'
            html << %Q{<tr><td>#{minus}</td><td>&#160;</td><td class="code minus">#{escape_html line}</td></tr>}
            minus += 1
          elsif line[0..0] == '+'
            html << %Q{<tr><td>&#160;</td><td>#{plus}</td><td class="code plus">#{escape_html line}</td></tr>}
            plus += 1
          else
            html << %Q{<tr><td>#{minus}</td><td>#{plus}</td><td class="code">#{escape_html line}</td></tr>}
            minus += 1
            plus += 1
          end
        end
      end
      html << '</tbody></table>' if !html.empty?
      html
    end

    def date(t)
      %Q{<span class="date seconds_#{t.to_i}">#{t.strftime('%d %h %Y %H:%M')}</span>}
    end

    def breadcrumbs(resource)
      path = resource.respond_to?(:path) ? resource.path : ''
      links = [%Q{<a href="#{resource_path(resource, :path => '/root')}">&#8730;&#175; Root</a>}]
      path.split('/').inject('') do |parent,elem|
        links << %Q{<a href="#{resource_path(resource, :path => (parent/elem).urlpath)}">#{elem}</a>}
        parent/elem
      end

      result = []
      links.each_with_index do |link,i|
        result << %Q{<li class="breadcrumb#{i==0 ? ' first' : ''}#{i==links.size-1 ? ' last' : ''}">#{link}</li>}
      end
      result.join(%Q{<li class="breadcrumb">/</li>})
    end

    def resource_path(resource, opts = {})
      sha = opts.delete(:sha) || (resource && !resource.current? && resource.commit) || ''
      sha = sha.sha if sha.respond_to?(:sha)
      if path = opts.delete(:path)
        if !path.begins_with? '/'
          path = resource.page? ? resource.path/'..'/path : resource.path/path
        end
      else
        path = resource.path
      end
      path = (path/sha).urlpath
      path << '?' << opts.map {|k,v| "#{k}=#{CGI.escape(v.to_s)}" }.join('&') if !opts.empty?
      path
    end

    def action_path(path, action)
      path = path.path if path.respond_to? :path
      (path.to_s/action.to_s).urlpath
    end

    def tab_selected(action)
      action?(action) ? {:class=>'tabs-selected'} : {}
    end

    def show_messages
      if session[:messages]
        out = '<ul>'
        session[:messages].each do |msg|
          out += %Q{<li class="#{msg[0]}">#{escape_html msg[1]}</li>}
        end
        session.delete(:messages)
        out + '</ul>'
      else
        ''
      end
    end

    def message(level, *messages)
      session[:messages] ||= []
      messages.flatten.each do |msg|
        if msg.respond_to? :messages
          session[:messages] += msg.messages.map { |m| [level, m] }
        elsif msg.respond_to? :message
          session[:messages] << [level, msg.message]
        else
          session[:messages] << [level, msg]
        end
      end
    end

    def action?(name)
      if params[:action]
        params[:action] == name.to_s
      else
        request.path_info.ends_with? '/' + name.to_s
      end
    end

    def edit_content(page)
      return params[:content] if params[:content]
      return :no_text_file.t(:page => page.path, :mime => page.mime) if !page.mime.text?
      page.content(params[:pos], params[:len])
    end

  end
end

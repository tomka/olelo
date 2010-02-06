# -*- coding: utf-8 -*-
require 'wiki/utils'

module Wiki
  module BlockHelper
    lazy_reader(:blocks) { Hash.with_indifferent_access('') }

    def define_block(name, content = nil, &block)
      blocks[name] = block ? capture_haml(&block) : content
    end

    def include_block(name)
      safe_output do
        with_hooks(name) { blocks[name] }.to_s
      end
    end

    def render_block(name, &block)
      safe_output do
        with_hooks(name) { capture_haml(&block) }.to_s
      end
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
  end

  module PageHelper
    def safe_output
      yield
    rescue => ex
      @logger.error(ex) if @logger
      %{<span class="error">#{ex.message}</span>}
    end

    def theme_links
      default = File.basename(File.dirname(File.readlink(File.join(Config.root, 'static', 'themes', 'default'))))
      Dir.glob(File.join(Config.root, 'static', 'themes', '*', 'style.css')).map do |file|
        name = File.basename(File.dirname(file))
        next if name == 'default'
        %{<link rel="#{name == default ? 'alternate ' : ''}stylesheet" href="/static/themes/#{name}/style.css" type="text/css" title="#{name}"/>}
      end.compact.join("\n")
    end

    def format_changes(patch, opts = {})
      lines = patch.split("\n")
      html, path, header, last = '', nil, true, nil
      files, count = [], 0
      lines.each do |line|
        case line
        when %r{^diff ([\w\-\s]+?) "?a/(.+?)"? "?b/(.+?)"?$}
          path = Wiki.backslash_unescape($2)
          count += 1
          header = true
        when /^\+\+\+/
          html << '</span>' if last
          last = nil
          html << '</td></tr></tbody></table>' if !html.empty?
          if path
            html << %{<table class="changes" id="file-#{count}">}
            if opts[:from] && opts[:to]
              html << %{<thead><tr><th>
                          <a class="left" href="#{Wiki.html_escape path.urlpath}">#{path}</a>
                          <span class="right">
                            <a href="#{Wiki.html_escape((path/'version'/opts[:from].sha[0..4]).urlpath)}">#{opts[:from].sha[0..4]}</a> to
                            <a href="#{Wiki.html_escape((path/'version'/opts[:to].sha[0..4]).urlpath)}">#{opts[:to].sha[0..4]}</a>
                          </span>
                         </th></tr></thead>}.unindent
            else
              html << %{<thead><tr><th><a class="left" href="#{Wiki.html_escape path.urlpath}">#{Wiki.html_escape path}</a></th></tr></thead>}
            end
          else
            html << %{<table class="changes">}
          end
          html << %{<tbody><tr><td>}
        when /^(new|deleted)/
          files << [$1, path, count]
        else
          ch = line[0..0]
          if header
            header = false if ch == '@'
          else
            case ch
            when '@'
              html << '</span>' if last
              html << '</tr></td><tr><td>'
              last = nil
            when /-|\+| /
              html << '</span>' if last && last != ch
              html << "<span#{{'-' => ' class="minus"', '+' => ' class="plus"'}[ch]}>" if last != ch
              html << (line.length > 1 ? Wiki.html_escape(line[1..-1]) : '&#160;') << "\n"
              last = ch
            end
          end
        end
      end
      html << '</span>' if last
      html << '</td></tr></tbody></table>' if !html.empty?
      if files.empty?
        html
      else
        result = '<ul class="files">'
        files.each do |clazz, name, id|
          result << %{<li class="#{clazz}"><a href="#file-#{id}">#{Wiki.html_escape name}</a></li>}
        end
        result << '</ul>' << html
      end
    end

    def date(t)
      %{<span class="date epoch-#{t.to_i}">#{t.strftime('%d %h %Y %H:%M')}</span>}
    end

    def breadcrumbs(resource)
      path = resource.try(:path) || ''
      links = [%{<a href="#{Wiki.html_escape resource_path(resource, :path => '/root')}">#{:root_path.t}</a>}]
      path.split('/').inject('') do |parent,elem|
        links << %{<a href="#{Wiki.html_escape resource_path(resource, :path => (parent/elem).urlpath)}">#{Wiki.html_escape elem}</a>}
        parent/elem
      end

      result = []
      links.each_with_index do |link,i|
        result << %{<li class="breadcrumb#{i==0 ? ' first' : ''}#{i==links.size-1 ? ' last' : ''}">#{link}</li>}
      end
      result.join(%{<li class="breadcrumb">/</li>})
    end

    def resource_path(resource, opts = {})
      version = opts.delete(:version) || (resource && !resource.current? && resource.commit) || ''
      version = version.try(:sha) || version
      if path = opts.delete(:path)
        if !path.begins_with? '/'
          path = resource.page? ? resource.path/'..'/path : resource.path/path
        end
      else
        path = resource.path
      end
      path = (version.blank? ? path : path/'version'/version).urlpath
      path << '?' << Wiki.build_query(opts) if !opts.empty?
      path
    end

    def action_path(path, action)
      path = path.try(:path) || path
      (path.to_s/action.to_s).urlpath
    end

    def show_messages
      if session[:messages]
        out = '<ul>'
        session[:messages].each do |msg|
          out << %{<li class="#{msg[0]}">#{Wiki.html_escape msg[1]}</li>}
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
        @logger.debug(msg) if @logger
	if msg.respond_to? :messages
          session[:messages] += msg.messages.map { |m| [level, m] }
        elsif msg.respond_to? :message
          session[:messages] << [level, msg.message]
        else
          session[:messages] << [level, msg]
        end
      end
    end

    def edit_content(page)
      return params[:content] if params[:content]
      return :no_text_file.t(:page => page.path, :mime => page.mime) if !page.mime.text?
      page.content(params[:pos], params[:len])
    end
  end

  module CacheHelper
    # Cache control for resource
    def cache_control(opts)
      return if !Config.production?

      if opts[:no_cache]
        response.headers.delete('ETag')
        response.headers.delete('Last-Modified')
        response['Cache-Control'] = 'no-cache'
        return
      end

      last_modified = opts.delete(:last_modified)
      modified_since = env['HTTP_IF_MODIFIED_SINCE']
      last_modified = last_modified.try(:to_time) || last_modified
      last_modified = last_modified.try(:httpdate) || last_modified

      if @user && !@user.anonymous?
        # Always private mode if user is logged in
        opts[:private] = true

        # Special etag for authenticated user
        opts[:etag] = Wiki.md5("#{@user.name}#{opts[:etag]}") if opts[:etag]
      end

      if opts[:etag]
        value = '"%s"' % opts.delete(:etag)
        response['ETag'] = value
        response['Last-Modified'] = last_modified if last_modified
        if etags = env['HTTP_IF_NONE_MATCH']
          etags = etags.split(/\s*,\s*/)
          # Etag is matching and modification date matches (HTTP Spec §14.26)
          halt(304) if (etags.include?(value) || etags.include?('*')) && (!last_modified || last_modified == modified_since)
        end
      elsif last_modified
        # If-Modified-Since is only processed if no etag supplied.
        # If the etag match failed the If-Modified-Since has to be ignored (HTTP Spec §14.26)
        response['Last-Modified'] = last_modified
        halt(304) if last_modified == modified_since
      end

      opts[:public] = !opts[:private]
      opts[:max_age] ||= 0
      opts[:must_revalidate] ||= true if !opts.include?(:must_revalidate) && !opts[:proxy_revalidate]

      response['Cache-Control'] = opts.map do |k, v|
        if v == true
          k.to_s.gsub('_', '-')
        elsif v
          v = 31536000 if v.to_s == 'static'
          "#{k.to_s.gsub('_', '-')}=#{v}"
        end
      end.compact.join(', ')
    end
  end

  module ResponseHelper
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
  end

  module Helper
    include BlockHelper
    include PageHelper
    include CacheHelper
    include ResponseHelper

    def start_timer
      @start_time = Time.now
    end

    def elapsed_time
      ((Time.now - @start_time) * 1000).to_i
    end

    def tab_selected(action)
      action?(action) ? {:class=>'tabs-selected'} : {}
    end

    def action?(name)
      if params[:action]
        params[:action] == name.to_s
      else
        Wiki.uri_unescape(request.path_info).ends_with? '/' + name.to_s
      end
    end

    def session
      env['rack.session'] ||= {}
    end
  end
end

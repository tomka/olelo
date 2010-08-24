description 'System information'

class Olelo::Application
  get '/system' do
    GC.start
    @memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    render :system
  end
end

__END__
@@ system.haml
- title 'System Information'
%h1 System Information
%table.zebra
  %tr
    %td Ruby version:
    %td= RUBY_VERSION
  %tr
    %td Memory usage:
    %td #{@memory} MiB
%h2 Configuration
%table.zebra
  %tr
    %td Production mode:
    %td= Olelo::Config.production?
  %tr
    %td Repository backend:
    %td= Olelo::Config.repository.type
  %tr
    %td Authentication backend:
    %td= Olelo::Config.authentication.service
  %tr
    %td Locale:
    %td= Olelo::Config.locale
  %tr
    %td Sidebar page:
    %td
      %a{:href => absolute_path(Olelo::Config.sidebar_page)}= Olelo::Config.sidebar_page
  %tr
    %td Mime type detection order:
    %td= Olelo::Config.mime.join(', ')
- if Olelo.const_defined? 'Engine'
  %h2 Engines
  %p
    \Every page is rendered by an appropriate rendering engine. The engine is selected automatically, where engines with lower priority are preferred. An alternative output engine
    \can be selected using the view menu or manually using the "output" query parameter.
  %table.zebra.full
    %thead
      %tr
        %th Name
        %th Output Mime Type
        %th Accepted mime types
        %th Hidden
        %th Priority
    %tbody
      - Olelo::Engine.engines.values.flatten.each do |engine|
        %tr
          %td= engine.name
          %td= engine.mime
          %td= engine.accepts
          %td= engine.hidden?
          %td= engine.priority
- if Olelo.const_defined? 'Tag'
  %h2 Markup tags
  %p Markup tags can be included in the wikitext like normal html tags. These tags are provided by plugins as wikitext extensions.
  %table.zebra.full
    %thead
      %tr
        %th Name
        %th Description
        %th Provided by
        %th Required attributes
    %tbody
      - Olelo::Tag.tags.each do |name, tag|
        %tr
          %td= name
          %td= tag.description
          %td= tag.plugin.name
          %td= tag.requires.join(', ')
%h2 Plugins
%p These plugins are currently available on your installation.
%table.zebra.full
  %thead
    %tr
      %th Name
      %th Author
      %th Description
      %th Dependencies
  %tbody
    - Olelo::Plugin.plugins.sort_by(&:name).each do |plugin|
      %tr
        %td= plugin.name
        %td= plugin.author
        %td= plugin.description
        %td= plugin.dependencies.join(', ')
    - Olelo::Plugin.disabled.sort.each do |plugin|
      %tr
        %td #{plugin} (disabled)
        %td unknown
        %td unknown
        %td unknown
    - Olelo::Plugin.failed.sort.each do |plugin|
      %tr
        %td #{plugin} (failed)
        %td unknown
        %td unknown
        %td unknown

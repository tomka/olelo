description 'System information'

class Olelo::Application
  get '/system' do
    GC.start
    @plugins = Plugin.plugins.sort_by(&:name)
    @failed_plugins = Plugin.failed.sort
    @disabled_plugins = Plugin.disabled.sort
    @memory = `ps -o rss= -p #{Process.pid}`.to_i / 1024
    render :system
  end
end

__END__
@@ system.haml
- title 'System Information'
%h2 Runtime
%table.zebra
  %tr
    %td Ruby version:
    %td&= RUBY_VERSION
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
    %td&= Olelo::Config.repository.type
  %tr
    %td Authentication backend:
    %td&= Olelo::Config.authentication.service
  %tr
    %td Locale
    %td&= Olelo::Config.locale
  %tr
    %td External images enabled
    %td&= Olelo::Config.external_images?
  %tr
    %td Root path
    %td
      %a{:href=>Olelo::Config.root_path.urlpath}&= Olelo::Config.root_path
  %tr
    %td Sidebar page
    %td
      %a{:href=>Olelo::Config.sidebar_page.urlpath}&= Olelo::Config.sidebar_page
  %tr
    %td Directory index pages
    %td&= Olelo::Config.index_page
  %tr
    %td Mime type detection order
    %td&= Olelo::Config.mime.join(', ')
%h2 Plugins
%table.zebra.full
  %thead
    %tr
      %th Name
      %th Author
      %th Description
      %th Dependencies
  %tbody
    - @plugins.each do |plugin|
      %tr
        %td&= plugin.name
        %td&= plugin.author
        %td&= plugin.description
        %td&= plugin.dependencies.join(', ')
    - @disabled_plugins.each do |plugin|
      %tr
        %td
          &= plugin
          (disabled)
        %td unknown
        %td unknown
        %td unknown
    - @failed_plugins.each do |plugin|
      %tr
        %td
          &= plugin
          (failed)
        %td unknown
        %td unknown
        %td unknown

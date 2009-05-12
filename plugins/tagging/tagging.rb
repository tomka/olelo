require 'fileutils'

class Tagging
  def initialize
    @store ||= begin
                 FileUtils.mkdir_p File.dirname(Config.tagging.store), :mode => 0755
                 YAML::Store.new(Config.tagging.store)
               end
    @store.transaction do |store|
      store['resources'] ||= {}
      store['tags'] ||= {}
    end
  end

  def add(id, tag)
    @store.transaction do |store|
      (store['resources'][id] ||= []) << tag
      (store['tags'][tag] ||= []) << id
      store['resources'][id].uniq!
      store['tags'][tag].uniq!
    end
  end

  def delete(id, tag)
    @store.transaction do |store|
      (store['resources'][id] || []).delete(tag)
      (store['tags'][tag] || []).delete(id)
      store['resources'].delete(id) if store['resources'][id].blank?
      store['tags'].delete(tag) if store['tags'][tag].blank?
    end
  end

  def get(id)
    @store.transaction(true) do |store|
      store['resources'][id].to_a
    end
  end

  def get_all
    @store.transaction(true) do |store|
      store['tags'].keys.sort
    end
  end

  def find_by_tag(tag)
    @store.transaction(true) do |store|
      store['tags'][tag].to_a.sort
    end
  end
end

class Wiki::App
  def tagging
    @tagging ||= Tagging.new
  end

  add_hook(:after_content) do
    if @resource
      tags = tagging.get(@resource.path)
      result = '<div class="box"><strong>Tags:</strong> '
      tags.each do |tag|
        result << "<a href=\"/tags/#{tag}\">#{tag}</a><form class=\"inline\" method=\"post\" action=\"/tags/#{tag}\">" +
                  "<div><input type=\"hidden\" name=\"path\" value=\"#{@resource.path}\"/>" +
                  "<input type=\"hidden\" name=\"_method\" value=\"delete\"/>" +
                  "<button type=\"submit\">#{image :delete}</button></div></form>&#183;\n"
      end
      result +
        "<form class=\"inline\" method=\"post\" action=\"/tags/new\"><div><input type=\"hidden\" name=\"path\" value=\"#{@resource.path}\"/>" +
        "<input type=\"text\" name=\"tag\"/><button type=\"submit\">#{image :add}</button></div></form></div>"
    end
  end

  get '/tags/:tag' do
    @tag = params[:tag]
    @paths = tagging.find_by_tag(@tag)
    haml :tag
  end

  get '/tags' do
    @tags = tagging.get_all
    haml :tags
  end

  post '/tags/new' do
    tag = params[:tag].to_s.strip
    if !tag.blank?
      resource = Resource.find!(@repo, params[:path])
      tagging.add(resource.path, tag)
    end
    redirect resource_path(resource, :purge => 1)
  end

  delete '/tags/:tag' do
    tag = params[:tag].to_s.strip
    resource = Resource.find!(@repo, params[:path])
    tagging.delete(resource.path, tag)
    redirect resource_path(resource, :purge => 1)
  end
end

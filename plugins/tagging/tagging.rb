author      'Daniel Mendler'
description 'Tagging support'
require     'yaml'

class YamlPage < Page
  lazy_reader :data do
    data = YAML.load(content + "\n") rescue nil
    (Hash === data ? data : {}).with_indifferent_access
  end

  def write(message, author = nil)
    super(data.to_hash.to_yaml, message, author)
  end
end

class TagStore < YamlPage
  def add(id, tag, author)
    (data[id] ||= []) << tag
    data[id].uniq!
    write(:id_tagged_as.t(:id => id, :tag => tag), author)
  end

  def delete(id, tag, author)
    data[id].delete(tag) if data[id]
    data.delete(id) if data[id].blank?
    write(:tag_deleted.t(:tag => tag, :id => id), author)
  end

  def get(id)
    data[id].to_a
  end

  def get_all
    data.inject([]) do |result, (id, tags)|
      result + tags
    end.uniq.sort
  end

  def find_by_tag(tag)
    result = []
    data.each do |id, tags|
      result << id if tags.include?(tag)
    end.sort
    result
  end
end

class Wiki::App
  TAG_STORE = 'tags.yml'

  static_files '*.png'

  lazy_reader :tag_store do
    TagStore.find(repository, TAG_STORE) || TagStore.new(repository, TAG_STORE)
  end

  add_hook(:after_footer) do
    haml(:tagbox, :layout => false) if @resource && !@resource.new?
  end

  get '/tags/:tag' do
    @tag = params[:tag]
    @paths = tag_store.find_by_tag(@tag)
    haml :tag
  end

  get '/tags' do
    @tags = tag_store.get_all
    haml :tags
  end

  post '/tags/new' do
    tag = params[:tag].to_s.strip
    if !tag.blank?
      resource = Resource.find!(repository, params[:path])
      tag_store.add(resource.path, tag, @user)
    end
    redirect resource_path(resource, :purge => 1)
  end

  delete '/tags/:tag' do
    tag = params[:tag].to_s.strip
    resource = Resource.find!(repository, params[:path])
    tag_store.delete(resource.path, tag, @user)
    redirect resource_path(resource, :purge => 1)
  end
end

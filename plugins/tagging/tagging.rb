require 'yaml'

class Tagging
  TAGGING_STORE = 'tags.yml'

  def initialize(repo)
    @store = Page.find(repo, TAGGING_STORE)
    @store ||= Page.new(repo, TAGGING_STORE)
  end

  def add(id, tag, author)
    write(:id_tagged_as.t(:id => id, :tag => tag), author) do |store|
      (store['resources'][id] ||= []) << tag
      (store['tags'][tag] ||= []) << id
      store['resources'][id].uniq!
      store['tags'][tag].uniq!
      store
    end
  end

  def delete(id, tag, author)
    write(:tag_deleted.t(:tag => tag, :id => id), author) do |store|
      (store['resources'][id] || []).delete(tag)
      (store['tags'][tag] || []).delete(id)
      store['resources'].delete(id) if store['resources'][id].blank?
      store['tags'].delete(tag) if store['tags'][tag].blank?
      store
    end
  end

  def get(id)
    read['resources'][id].to_a
  end

  def get_all
    read['tags'].keys.sort
  end

  def find_by_tag(tag)
    read['tags'][tag].to_a.sort
  end

  private

  def read
    store = YAML.load(@store.content)
    store['resources'] ||= {}
    store['tags'] ||= {}
    store
  rescue
    {'resources' => {}, 'tags' => {}}
  end

  def write(msg, author, &block)
    store = read
    old = store.to_yaml
    new = block[store].to_yaml
    @store.write(new, msg, author) if (new != old)
  end
end

class Wiki::App
  def tagging
    @tagging ||= Tagging.new(@repo)
  end

  add_hook(:after_footer) do
    haml(:tagbox, :layout => false) if @resource
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
      tagging.add(resource.path, tag, @user.author)
    end
    redirect resource_path(resource, :purge => 1)
  end

  delete '/tags/:tag' do
    tag = params[:tag].to_s.strip
    resource = Resource.find!(@repo, params[:path])
    tagging.delete(resource.path, tag, @user.author)
    redirect resource_path(resource, :purge => 1)
  end
end

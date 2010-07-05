author      'Daniel Mendler'
description 'Tagging support'

class YamlPage < Page
  def data
    @data ||= begin
                data = YAML.load(content + "\n") rescue nil
                (Hash === data ? data : {}).with_indifferent_access
              end
  end

  def write
    super(data.to_hash.to_yaml)
  end
end

class TagStore < YamlPage
  def add(id, tag)
    (data[id] ||= []) << tag
    data[id].uniq!
    write
  end

  def delete(id, tag)
    data[id].delete(tag) if data[id]
    data.delete(id) if data[id].blank?
    write
  end

  def get(id)
    data[id].to_a.sort
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

class Wiki::Application
  TAG_STORE = 'tags.yml'

  assets '*.png'

  def tag_store
    @tag_store ||= TagStore.find(TAG_STORE) || TagStore.new(TAG_STORE)
  end

  hook :layout do |name, doc|
    doc.css('#footer').children.before(render(:tagbox, :layout => false)) if @resource && !@resource.new?
  end

  get '/tags/:tag' do
    @tag = params[:tag]
    @paths = tag_store.find_by_tag(@tag)
    render :tag
  end

  get '/tags' do
    @tags = tag_store.get_all
    render :tags
  end

  post '/tags/new' do
    tag = params[:tag].to_s.strip
    Resource.transaction(:tag_added.t(:path => params[:path].cleanpath, :tag => tag), user) do
      @resource = Resource.find!(params[:path])
      tag_store.add(@resource.path, tag) if !tag.blank?
    end
    redirect resource_path(@resource, :purge => 1)
  end

  delete '/tags/:tag' do
    tag = params[:tag].to_s.strip
    Resource.transaction(:tag_deleted.t(:path => params[:path].cleanpath, :tag => tag), user) do
      @resource = Resource.find!(params[:path])
      tag_store.delete(@resource.path, tag)
    end
    redirect resource_path(@resource, :purge => 1)
  end
end

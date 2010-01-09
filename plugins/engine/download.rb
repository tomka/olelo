author      'Daniel Mendler'
description 'Download engine'

Engine.create(:download, :priority => 999, :layout => false) do
  def accepts?(resource); true; end
  def mime(resource); resource.tree? ? 'application/zip' : resource.mime; end
  def response(opts)
    resource = opts[:resource]
    response = opts[:response]
    if resource.tree?
      file = Tempfile.new('archive').path
      resource.repository.git_archive(resource.commit.sha, nil, '--format=zip', "--prefix=#{resource.safe_name}/", "--output=#{file}")
      response['Content-Disposition'] = 'attachment; filename="%s.zip"' % resource.safe_name
      response['Content-Length'] = File.stat(file).size.to_s
      BlockFile.open(file, 'rb')
    else
      response['Content-Disposition'] = 'attachment; filename="%s"' % resource.safe_name
      resource.content
    end
  end
end

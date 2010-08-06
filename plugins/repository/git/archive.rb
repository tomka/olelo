description  'Archive engine for git repository'
dependencies 'engine/engine'

raise 'Git repository required' if Config.repository.type != 'git'

Engine.create(:archive, :accepts => Tree::MIME, :mime => 'application/zip') do
  def output(context)
    tree = context.tree
    response = context.response
    file = Tempfile.new('archive').path
    git = Repository.instance.git
    git.git_archive('--format=zip',
                    "--prefix=#{tree.safe_name}/",
                    "--output=#{file}",
                    "#{tree.version}:#{tree.path}")
    response['Content-Disposition'] = 'attachment; filename="%s.zip"' % tree.safe_name
    response['Content-Length'] = File.stat(file).size.to_s
    BlockFile.open(file, 'rb')
  end
end

author      'Daniel Mendler'
description 'Archive engine for git repository'
dependencies 'engine/engine', 'repository/git/git'

Engine.create(:archive, :priority => 999, :layout => false) do
  def accepts?(resource); resource.tree?; end
  def mime(resource); 'application/zip'; end
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

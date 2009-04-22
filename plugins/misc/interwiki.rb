setup do
  interwiki = YAML.load_file(File.join(Config.root, 'interwiki.yml'))
  App.get %r{^/(#{interwiki.keys.join('|')}):(.+)$} do
    redirect(interwiki[params[:captures][0]] + params[:captures][1])
  end
end

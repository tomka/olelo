description  'Pandoc filter'
dependencies 'engine/filter'

class Pandoc < Filter
  def initialize(options)
    super
    @command = "pandoc --to=#{options[:to]} --from=#{options[:from]}"
  end

  def filter(content)
    shell_filter(@command, content)
  end
end

Filter.register :pandoc, Pandoc

description  'XSLT filter which transforms a html page to a S5 presentation'
dependencies 'filter/xslt', 'utils/assets'
export_assets 'ui/**/*', 'ui/default/*'

Application.attribute_editor do
  group :s5 do
    attribute :presdate, :string
    attribute :author, :string
    attribute :company, :string
    attribute :theme, :string
    attribute :transitions, :string
    attribute :fadeDuration, :integer
    attribute :incrDuration, :integer
  end
end

class S5 < XSLT
  def configure(options)
    super(options.merge(:stylesheet => 's5/s5.xsl'))
  end

  def params(context)
    themes = Dir.glob(File.join(File.dirname(__FILE__), 'ui', '*')).map {|name| File.basename(name) }
    themes.delete('common')
    themes.delete('default')
    themes.unshift(context.page.attributes['theme'] || 'default')
    super.merge(context.page.attributes['s5'] || {}).
      merge('themes' => themes.join(' '), 's5_path' => absolute_path('_/assets/filter/s5'))
  end
end

Filter.register :s5, S5

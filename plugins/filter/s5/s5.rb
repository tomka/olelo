description  'S5 presentation filter'
dependencies 'filter/xslt', 'utils/asset_manager'

class Olelo::Application
  register_attribute :presdate, :string
  register_attribute :author, :string
  register_attribute :company, :string
  register_attribute :theme, :string
  register_attribute :transitions, :string
  register_attribute :fadeDuration, :integer
  register_attribute :incrDuration, :integer
end

class S5 < XSLT
  def initialize(options)
    super(:stylesheet => 's5/s5.xsl')
  end

  def params(context)
    themes = Dir.glob(File.join(File.dirname(__FILE__), 'ui', '*')).map {|name| File.basename(name) }
    themes.delete('common')
    themes.delete('default')
    themes.unshift(context.page.attributes['theme'] || 'default')
    super.merge('themes' => themes.join(' '), 's5_path' => absolute_path('_/assets/filter/s5'))
  end
end

Filter.register :s5, S5
AssetManager.register_assets 'ui/**/*', 'ui/default/*'

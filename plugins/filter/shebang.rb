Wiki::Plugin.define 'filter/shebang' do
  depends_on 'engine/filter'

  Wiki::Filter.create :shebang do |content|
    content.sub(/^#!(\w+)\s+/,'')
  end
end

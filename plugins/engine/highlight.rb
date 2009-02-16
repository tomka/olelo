Wiki::Plugin.define 'engine/highlight' do
  Wiki::Engine.create(:highlight, 2, true) do
    accepts { |page| Wiki::Highlighter.supports?(page.name) }

    output do |page|
      Wiki::Cache.cache('highlight', page.sha, :disable => !page.saved?) {
        Wiki::Highlighter.file(page.content, page.name)
      }
    end

  end
end

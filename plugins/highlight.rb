Wiki::Plugin.define :highlight do
  Wiki::Engine.create(:highlight, 2, true) do
    accepts { |page| Highlighter.supports?(page.name) }

    output do |page|
      Cache.cache('highlight', page.sha, :disable => !page.saved?) {
        Highlighter.file(page.content, page.name)
      }
    end

  end
end

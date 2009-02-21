Wiki::Plugin.define 'misc/highlight_patch' do
  depends_on 'misc/pygments'

  module Wiki::Helper
    def format_patch(diff)
      Pygments.pygmentize(diff.patch, :format => 'diff', :cache => true)
    end
  end
end

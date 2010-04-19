author       'Daniel Mendler'
description  'Export variables to context and javascript'
dependencies 'engine/engine'
require      'json'

# Export variables to engine context
Wiki::Context.hook(:initialized) do
  params['page_name'] = page.name
  params['page_path'] = page.path
  params['page_title'] = page.title
  params['page_version'] = page.commit ? page.commit.sha : ''
  params['is_current'] = page.current?
  params['is_discussion'] = page.discussion?
  params['is_meta'] = page.meta?
  params['page_mime'] = page.mime.to_s
end

# Export variables to javascript for client extensions
class Wiki::Application
  def escape_javascript(x)
    x.to_json.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  hook(:before_head) do
    %{<script type="text/javascript">
        Wiki = #{escape_javascript(@context ? @context.params : params)};
      </script>}.unindent
  end

  get '/_/user' do
    %{<script type="text/javascript">
      Wiki.user_anonymous = #{escape_javascript @user.anonymous?};
      Wiki.user_name = #{escape_javascript @user.name.to_json};
    </script>}.unindent + super()
  end
end

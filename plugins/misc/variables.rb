author       'Daniel Mendler'
description  'Export variables to context and javascript'
dependencies 'engine/engine'
require      'json'

def variables(page, engine)
  vars = {
    'page_name'     => page.name,
    'page_path'     => page.path,
    'page_title'    => page.title,
    'page_version'  => page.commit ? page.commit.sha : '',
    'page_type'     => page.tree? ? 'tree' : 'page',
    'is_current'    => page.current?,
    'is_discussion' => page.discussion?,
    'is_meta'       => page.meta?,
    'page_mime'     => page.mime.to_s }
  if engine
    vars.merge!({
      'engine_name'      => engine.name,
      'engine_layout'    => engine.layout?,
      'engine_cacheable' => engine.cacheable?,
      'engine_priority'  => engine.priority })
  end
  vars
end

def build_json(vars)
  vars.to_json.gsub('<', '&lt;').gsub('>', '&gt;')
end

# Export variables to engine context
Wiki::Context.hook(:initialized) do
  params.merge!(Plugin.current.variables(page, engine))
end

# Export variables to javascript for client extensions
class Wiki::Application
  hook(:before_head) do
    vars = @resource ? params.merge(Plugin.current.variables(@resource, @engine)) : params
    %{<script type="text/javascript">
        Wiki = #{Plugin.current.build_json(vars)};
      </script>}.unindent
  end

  get '/_/user' do
    %{<script type="text/javascript">
      Wiki.user_anonymous = #{Plugin.current.build_json @user.anonymous?};
      Wiki.user_name = #{Plugin.current.build_json @user.name};
    </script>}.unindent + super()
  end
end

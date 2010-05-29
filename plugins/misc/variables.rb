author       'Daniel Mendler'
description  'Export variables to context and javascript'
dependencies 'engine/engine'
require      'json'

def variables(page, engine)
  vars = {
    'page_name'             => page.name,
    'page_path'             => page.path,
    'page_namespace'        => page.namespace,
    'page_title'            => page.title,
    'page_version'          => page.version.to_s,
    'page_next_version'     => page.next_version.to_s,
    'page_previous_version' => page.previous_version.to_s,
    'page_type'             => page.tree? ? 'tree' : 'page',
    'page_mime'             => page.mime.to_s,
    'page_current'          => page.current? }
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
  vars = vars.to_json
  vars.gsub!('&', '&amp;')
  vars.gsub!('<', '&lt;')
  vars.gsub!('>', '&gt;')
  vars
end

# Export variables to engine context
Wiki::Context.hook(:initialized) do
  params.merge!(Plugin.current.variables(page, engine))
end

# Export variables to javascript for client extensions
class Wiki::Application
  before :head do
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

description  'Export variables to context and javascript'
dependencies 'engine/engine'
require      'yajl/json_gem'

def variables(page)
  vars = {
    'page_name'             => page.name,
    'page_new'              => page.new?,
    'page_modified'         => page.modified?,
    'page_path'             => page.path,
    'page_title'            => page.title,
    'page_version'          => page.version.to_s,
    'page_next_version'     => page.next_version.to_s,
    'page_previous_version' => page.previous_version.to_s,
    'page_mime'             => page.mime.to_s,
    'page_current'          => page.current?
  }
end

# Export variables to engine context
Olelo::Context.hook(:initialized) do
  params.merge!(Plugin.current.variables(page))
end

# Export variables to javascript for client extensions
class Olelo::Application
  hook :layout do |name, doc|
    vars = page ? params.merge(Plugin.current.variables(page)) : params
    vars.merge!('user_anonymous' => user.anonymous?, 'user_name' => user.name)
    doc.css('head').children.before %{<script type="text/javascript">
                                      Olelo = #{escape_json(vars.to_json)};
                                      </script>}.unindent
  end
end

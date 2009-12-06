author       'Daniel Mendler'
description  'Markitup Editor'

class Wiki::App

  add_hook(:after_head) do
    path = request.path_info
    if path.ends_with?('edit') || path.ends_with?('new') || path.ends_with?('upload')
      '<link rel="stylesheet" href="/sys/markitup/src/skins/markitup/style.css" type="text/css"/>' +
        '<link rel="stylesheet" href="/sys/markitup/src/sets/default/style.css" type="text/css"/>'
    end
  end

  add_hook(:after_script) do
    path = request.path_info
    if path.ends_with?('edit') || path.ends_with?('new') || path.ends_with?('upload')
      '<script type="text/javascript" src="/sys/markitup/src/jquery.markitup.js"></script>' +
        '<script type="text/javascript" src="/sys/markitup/src/sets/default/set.js"></script>' +
        '<script type="text/javascript">$(function(){ $("#text-content").markItUp(mySettings); });</script>'
    end
  end

  static_files 'src/**/*'
end

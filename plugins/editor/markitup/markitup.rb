author       'Daniel Mendler'
description  'Markitup Editor'

class Wiki::App
  hook(:after_style) do
    path = request.path_info
    if path.ends_with?('edit') || path.ends_with?('new') || path.ends_with?('upload')
      '<link rel="stylesheet" href="/_/markitup/src/skins/markitup/style.css" type="text/css"/>' +
        '<link rel="stylesheet" href="/_/markitup/src/sets/default/style.css" type="text/css"/>'
    end
  end

  hook(:after_script) do
    path = request.path_info
    if path.ends_with?('edit') || path.ends_with?('new') || path.ends_with?('upload')
      '<script type="text/javascript" src="/_/markitup/src/jquery.markitup.js"></script>' +
        '<script type="text/javascript" src="/_/markitup/src/sets/default/set.js"></script>' +
        '<script type="text/javascript">$(function(){ $("#text-content").markItUp(mySettings); });</script>'
    end
  end

  assets 'src/**/*'
end

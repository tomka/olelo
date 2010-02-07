author       'Daniel Mendler'
description  'HTML filter'

Filter.create :html do |content|
  %{<?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head><title>#{context.resource.title}</title></head>
      <body><h1>#{context.resource.title}</h1><div>#{content}</div></body>
    </html>}.unindent
end

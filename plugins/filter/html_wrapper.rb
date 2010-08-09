description  'Wraps fragment into html block to make it valid'
dependencies 'engine/filter'

Filter.create :html_wrapper do |context, content|
  content = %{<?xml version="1.0" encoding="UTF-8"?>
              <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1 plus MathML 2.0 plus SVG 1.1//EN" "http://www.w3.org/2002/04/xhtml-math-svg/xhtml-math-svg-flat.dtd" >
              <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                  <title>#{context.resource.title}</title>
                </head>
                <body><div>#{content}</div></body>
              </html>}.unindent
  # Unwrap after subfilters
  if sub
    content = subfilter(context, content)
    content.gsub!(/^.*<body>/m, '')
    content.gsub!(/<\/body>.*$/m, '')
  end
  content
end

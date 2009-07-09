require 'tempfile'

class Wiki::App
  add_hook(:before_edit_form_buttons) do
    "<input type=\"submit\" name=\"preview\" value=\"#{:preview.t}\"/>\n" +
    "<input type=\"submit\" name=\"changes\" value=\"#{:changes.t}\"/>\n"
  end

  add_hook(:before_edit_form) do
    if @preview
      "<div class=\"preview\">#{@preview}</div>"
    elsif @patch
      format_patch(@patch)
    end
  end

  add_hook(:page_text_edited) do |content|
    if params[:preview]
      message(:error, :empty_commit_message.t) if params[:message].empty?

      @resource.content = content
      if @resource.mime.text?
        engine = Engine.find!(@resource)
        @preview = engine.render(@resource) if engine.layout?
      end
      halt haml(request.put? ? :edit : :new)
    elsif params[:changes]
      message(:error, :empty_commit_message.t) if params[:message].empty?

      original = Tempfile.new('original')
      original.write(@resource.content)
      original.close

      new = Tempfile.new('new')
      new.write(content)
      new.close

      @patch = `diff -u "#{original.path}" #{new.path}`
      halt haml(request.put? ? :edit : :new)
    end
  end
end

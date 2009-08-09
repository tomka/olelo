author       'Daniel Mendler'
description  'Enhanced edit form with preview and diff'
require      'tempfile'

class Wiki::App
  add_hook(:before_edit_form_buttons) do
    %Q{<input type="checkbox" name="minor" id="minor" value="1"#{params[:minor] ? ' checked="checked"' : ''}/>
<label for="minor">Minor changes</label><br/>
<input type="submit" name="preview" value="#{:preview.t}"/>
<input type="submit" name="changes" value="#{:changes.t}"/>}
  end

  add_hook(:before_edit_form) do
    if @preview
      "<div class=\"preview\">#{@preview}</div>"
    elsif @patch
      format_patch(@patch)
    end
  end

  add_hook(:before_page_save) do |page|
    if (action?(:new) || action?(:edit)) && params[:content]
      if params[:preview]
        message(:error, :empty_commit_message.t) if params[:message].blank? && !params[:minor]

        page.content = params[:content]
        if page.mime.text?
          engine = Engine.find!(page)
          @preview = engine.render(page) if engine.layout?
        end
        halt haml(request.put? ? :edit : :new)
      elsif params[:changes]
        message(:error, :empty_commit_message.t) if params[:message].blank? && !params[:minor]

        original = Tempfile.new('original')
        original.write(page.content(params[:pos], params[:len]))
        original.close

        new = Tempfile.new('new')
        new.write(params[:content])
        new.close

        @patch = `diff -u "#{original.path}" #{new.path}`
        halt haml(request.put? ? :edit : :new)
      else
        params[:message] = :minor_changes.t if params[:minor] && params[:message].blank?
      end
    end
  end
end

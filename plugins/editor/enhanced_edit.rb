author      'Daniel Mendler'
description 'Enhanced edit form with preview and diff'

class Wiki::App
  hook(:before_edit_form_buttons) do
    %{<input type="checkbox" name="minor" id="minor" value="1"#{params[:minor] ? ' checked="checked"' : ''}/>
<label for="minor">Minor changes</label><br/>
<button type="submit" name="preview">#{:preview.t}</button>
<button type="submit" name="changes">#{:changes.t}</button>}
  end

  hook(:before_edit_form) do
    if @preview
      %{<div class="preview">#{@preview}</div>}
    elsif @patch
      format_changes(@patch)
    end
  end

  hook(:before_page_save) do |page|
    if (action?(:new) || action?(:edit)) && params[:content]
      if params[:preview]
        message(:error, :empty_commit_message.t) if params[:message].blank? && !params[:minor]

        page.content = params[:content]
        if page.mime.text?
          engine = Engine.find!(page)
          @preview = engine.render(:resource => page, :logger => @logger) if engine.layout?
        end
        halt haml(request.put? ? :edit : :new)
      elsif params[:changes]
        message(:error, :empty_commit_message.t) if params[:message].blank? && !params[:minor]

        original = Tempfile.new('original')
        original.write(page.content(params[:pos], params[:len]))
        original.close

        new = Tempfile.new('new')
        new.write(params[:content].gsub("\r\n", "\n"))
        new.close

        # Read in binary mode and fix encoding afterwards
        @patch = IO.popen("diff -u '#{original.path}' '#{new.path}'", 'rb') {|io| io.read }
        @patch.force_encoding(__ENCODING__)

	halt haml(request.put? ? :edit : :new)
      else
        params[:message] = :minor_changes.t if params[:minor] && params[:message].blank?
      end
    end
  end
end

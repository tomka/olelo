description  'Enhanced edit form with preview and diff'
dependencies 'engine/engine'

class Olelo::Application
  hook :layout do |name, doc|
    if name == :edit || name == :new
      if @preview
        doc.css('#page .tabs').before %{<div class="preview">#{@preview}</div>}
      elsif @patch
        doc.css('#page .tabs').before format_patch(@patch)
      end

      doc.css('#tab-edit button[type=submit]').before(
        %{<input type="checkbox" name="minor" id="minor" value="1"#{params[:minor] ? ' checked="checked"' : ''}/>
          <label for="minor">#{:minor_changes.t}</label><br/>
          <button type="submit" name="preview" accesskey="p">#{:preview.t}</button>
          <button type="submit" name="changes" accesskey="c">#{:changes.t}</button>}.unindent)
    end
  end

  before :save do |page|
    if (action?(:new) || action?(:edit)) && params[:content]
      if params[:preview]
        flash.error :empty_comment.t if params[:comment].blank? && !params[:minor]

        if page.mime.text?
          if params[:pos]
            # We assume that engine stays the same if section is edited
            engine = Engine.find!(page, :layout => true)
            page.content = params[:content]
          else
            # Whole page edited, assign new content before engine search
            page.content = params[:content]
            engine = Engine.find!(page, :layout => true)
          end
          if engine
            context = Context.new(:resource => page, :logger => logger, :engine => engine)
            @preview = engine.output(context)
          end
        end

        halt render(request.put? ? :edit : :new)
      elsif params[:changes]
        flash.error :empty_comment.t if params[:comment].blank? && !params[:minor]

        original = Tempfile.new('original')
        original.write(page.content(params[:pos], params[:len]))
        original.close

        new = Tempfile.new('new')
        new.write(params[:content].gsub("\r\n", "\n"))
        new.close

        # Read in binary mode and fix encoding afterwards
        @patch = IO.popen("diff -u '#{original.path}' '#{new.path}'", 'rb') {|io| io.read }
        @patch.force_encoding(__ENCODING__) if @patch.respond_to? :force_encoding

	halt render(request.put? ? :edit : :new)
      else
        params[:comment] = :minor_changes.t if params[:minor] && params[:comment].blank?
      end
    end
  end
end

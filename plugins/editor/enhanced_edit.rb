description  'Enhanced edit form with preview and diff'
dependencies 'engine/engine'

class Olelo::Application
  hook :layout do |name, doc|
    if name == :edit || name == :new
      if @preview
        doc.css('#content .tabs').before %{<div class="preview">#{@preview}</div>}
      elsif @patch
        doc.css('#content .tabs').before @patch
      end

      doc.css('#tab-edit button[type=submit]').before(
        %{<button type="submit" name="preview" accesskey="p">#{:preview.t}</button>
          <button type="submit" name="changes" accesskey="c">#{:changes.t}</button>}.unindent)
    end
  end

  before :save do |page|
    if (action?(:new) || action?(:edit)) && params[:content]
      if params[:preview]
        flash.error :empty_comment.t if params[:comment].blank?

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
          @preview = engine.output(Context.new(:page => page, :engine => engine))
        end

        halt render(request.put? ? :edit : :new)
      elsif params[:changes]
        flash.error :empty_comment.t if params[:comment].blank?

        original = Tempfile.new('original')
        original.write(page.content[params[:pos].to_i, params[:len].to_i])
        original.close

        new = Tempfile.new('new')
        new.write(params[:content].gsub("\r\n", "\n"))
        new.close

        # Read in binary mode and fix encoding afterwards
        patch = IO.popen("diff -u '#{original.path}' '#{new.path}'", 'rb') {|io| io.read }
        patch.force_encoding(__ENCODING__) if patch.respond_to? :force_encoding
        @patch = PatchParser.parse(patch, PatchFormatter.new).html

	halt render(request.put? ? :edit : :new)
      end
    end
  end
end

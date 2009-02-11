module Wiki
  Engine.create(:html, 3, true) do
    accepts {|page| page.mime.text? }
    output  {|page| '<pre>' + CGI::escapeHTML(page.content) + '</pre>' }
    mime    {|page| page.mime }
  end
end


Wiki::Plugin.define :raw do
  Wiki::Engine.create(:raw, 5, false) do
    accepts {|page| true }
    output  {|page| page.content }
    mime    {|page| page.mime }
  end
end

require 'wiki/highlighter'

class TC_Highlighter < Test::Unit::TestCase
  def test_text
    assert_equal '<table class="highlighttable"><tr><td class="linenos"><pre>1</pre></td><td class="code"><div class="highlight"><pre><span class="k">return</span> <span class="mi">1</span>
</pre></div>
</td></tr></table>', Wiki::Highlighter.text('return 1', 'ruby')
    assert_equal '&lt;&amp;&gt;', Wiki::Highlighter.text('<&>', 'unknown')
  end

  def test_file
    assert_equal '<table class="highlighttable"><tr><td class="linenos"><pre>1</pre></td><td class="code"><div class="highlight"><pre><span class="k">return</span> <span class="mi">1</span>
</pre></div>
</td></tr></table>', Wiki::Highlighter.file('return 1', 'file.rb')
    assert_equal '&lt;&amp;&gt;', Wiki::Highlighter.file('<&>', 'name.unknown')
  end

  def test_supports?
    assert Wiki::Highlighter.supports?('name.rb')
    assert Wiki::Highlighter.supports?('name.py')
    assert Wiki::Highlighter.supports?('name.html')
    assert Wiki::Highlighter.supports?('name.java')
  end
end

require 'test/unit'
require 'wiki'

class TC_Highlighter < Test::Unit::TestCase
  def test_text
    assert_equal '<table class="highlighttable"><tr><td class="linenos"><pre>1</pre></td><td class="code"><div class="highlight"><pre><span class="k">return</span> <span class="mi">1</span>
</pre></div>
</td></tr></table>', Highlighter.text('return 1', 'ruby')
    assert_equal '&lt;&amp;&gt;', Highlighter.text('<&>', 'unknown')
  end

  def test_file
    assert_equal '<table class="highlighttable"><tr><td class="linenos"><pre>1</pre></td><td class="code"><div class="highlight"><pre><span class="k">return</span> <span class="mi">1</span>
</pre></div>
</td></tr></table>', Highlighter.file('return 1', 'file.rb')
    assert_equal '&lt;&amp;&gt;', Highlighter.file('<&>', 'name.unknown')
  end

  def test_supports?
    assert Highlighter.supports?('name.rb')
    assert Highlighter.supports?('name.py')
    assert Highlighter.supports?('name.html')
    assert Highlighter.supports?('name.java')
  end
end

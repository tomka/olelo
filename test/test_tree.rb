require 'git_support'

class TC_Tree < Test::Unit::TestCase
  include GitSupport

  def page(name)
    p = Wiki::Page.new(@repo, name)
    p.write('content', 'message', 'Author <author@localhorst>')
  end

  def test_children
    page('page1')
    page('page2')
    page('page3')
    page('tree1/subpage1')
    page('tree1/subpage2')
    page('tree1/subpage3')
    page('tree2/subpage1')
    page('tree2/subpage2')
    page('tree2/subpage3')
    page('tree3/subpage1')
    page('tree3/subpage2')
    page('tree3/subpage3')
    page('tree1/subtree1/subsubpage1')
    page('tree1/subtree1/subsubpage2')
    page('tree1/subtree1/subsubpage3')

    tree = Wiki::Tree.find!(@repo, '/')
    assert_equal 7, tree.children.size
    assert_equal 'tree1', tree.children[0].path
    assert_equal 'tree2', tree.children[1].path
    assert_equal 'tree3', tree.children[2].path
    assert_equal 'init.txt', tree.children[3].path
    assert_equal 'page1', tree.children[4].path
    assert_equal 'page2', tree.children[5].path
    assert_equal 'page3', tree.children[6].path

    assert tree.children[0].tree?
    assert tree.children[1].tree?
    assert tree.children[2].tree?
    assert tree.children[3].page?
    assert tree.children[4].page?
    assert tree.children[5].page?
    assert tree.children[6].page?

    tree = Wiki::Tree.find!(@repo, '/tree1')
    assert_equal 4, tree.children.size
    assert_equal 'tree1/subtree1', tree.children[0].path
    assert_equal 'tree1/subpage1', tree.children[1].path
    assert_equal 'tree1/subpage2', tree.children[2].path
    assert_equal 'tree1/subpage3', tree.children[3].path

    assert tree.children[0].tree?
    assert tree.children[1].page?
    assert tree.children[2].page?
    assert tree.children[3].page?
    
    tree = Wiki::Tree.find!(@repo, '/tree1/subtree1')
    assert_equal 3, tree.children.size
    assert_equal 'tree1/subtree1/subsubpage1', tree.children[0].path
    assert_equal 'tree1/subtree1/subsubpage2', tree.children[1].path
    assert_equal 'tree1/subtree1/subsubpage3', tree.children[2].path    

    assert tree.children[0].page?
    assert tree.children[1].page?
    assert tree.children[2].page?
  end
end

require 'spec_setup'

describe 'Wiki::Tree' do
  before { create_repository }
  after { destroy_repository }

  it 'should have children' do
    create_page('page1')
    create_page('page2')
    create_page('page3')

    tree = Wiki::Tree.find!(@repo, '/')
    tree.should.be.current

    tree.commit.sha.should.equal tree.children[0].commit.sha
    tree.commit.sha.should.equal tree.children[1].commit.sha
    tree.commit.sha.should.equal tree.children[2].commit.sha
    tree.children[0].should.be.current
    tree.children[1].should.be.current
    tree.children[2].should.be.current

    old_tree = Wiki::Tree.find(@repo, '/', tree.prev_commit)
    old_tree.should.not.be.current
    tree.prev_commit.sha.should.equal old_tree.commit.sha
    old_tree.commit.sha.should.equal old_tree.children[0].commit.sha
    old_tree.commit.sha.should.equal old_tree.children[1].commit.sha
    old_tree.commit.sha.should.equal old_tree.children[2].commit.sha
    old_tree.children[0].should.not.be.current
  end

  it "children" do
    create_page('page1')
    create_page('page2')
    create_page('page3')
    create_page('tree1/subpage1')
    create_page('tree1/subpage2')
    create_page('tree1/subpage3')
    create_page('tree2/subpage1')
    create_page('tree2/subpage2')
    create_page('tree2/subpage3')
    create_page('tree3/subpage1')
    create_page('tree3/subpage2')
    create_page('tree3/subpage3')
    create_page('tree1/subtree1/subsubpage1')
    create_page('tree1/subtree1/subsubpage2')
    create_page('tree1/subtree1/subsubpage3')

    tree = Wiki::Tree.find!(@repo, '/')
    tree.children.size.should.equal 7
    tree.children[0].path.should.equal 'tree1'
    tree.children[1].path.should.equal 'tree2'
    tree.children[2].path.should.equal 'tree3'
    tree.children[3].path.should.equal 'Home'
    tree.children[4].path.should.equal 'page1'
    tree.children[5].path.should.equal 'page2'
    tree.children[6].path.should.equal 'page3'

    tree.children[0].should.be.tree
    tree.children[1].should.be.tree
    tree.children[2].should.be.tree
    tree.children[3].should.be.page
    tree.children[4].should.be.page
    tree.children[5].should.be.page
    tree.children[6].should.be.page

    tree = Wiki::Tree.find!(@repo, '/tree1')
    tree.children.size.should.equal 4
    tree.children[0].path.should.equal 'tree1/subtree1'
    tree.children[1].path.should.equal 'tree1/subpage1'
    tree.children[2].path.should.equal 'tree1/subpage2'
    tree.children[3].path.should.equal 'tree1/subpage3'

    tree.children[0].should.be.tree
    tree.children[1].should.be.page
    tree.children[2].should.be.page
    tree.children[3].should.be.page

    tree = Wiki::Tree.find!(@repo, '/tree1/subtree1')
    tree.children.size.should.equal 3
    tree.children[0].path.should.equal 'tree1/subtree1/subsubpage1'
    tree.children[1].path.should.equal 'tree1/subtree1/subsubpage2'
    tree.children[2].path.should.equal 'tree1/subtree1/subsubpage3'

    tree.children[0].should.be.page
    tree.children[1].should.be.page
    tree.children[2].should.be.page
  end
end

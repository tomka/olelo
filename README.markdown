README
======

Git-Wiki is a a wiki that stores pages in a git repository.

Demo installation at <http://git-wiki.kicks-ass.org/>

Features
--------

- History
- Show diffs
- Edit page, append to page, upload files
- Plugin system
- Multiple renderers
- LaTeX/Graphviz
- Syntax highlighting (embedded code blocks)
- Image support, SVG support
- Auto-generated table of contents
- Templates

Installation
------------

At first you have to install the gem dependencies via "gem".

    gem sources -a http://gems.github.org/
    gem install minad-creole
    gem install minad-git
    gem install minad-rack-esi
    gem install rack-cache
    gem install haml
    gem install thin
    gem install rack

Optional:
    gem install hpricot
    gem install rdiscount
    gem install RedCloth
    gem install rubypants
    gem install RMagick
    gem install minad-imaginator

Then run with `./run.ru -sthin -p4567` and. point your browser at <http://localhost:4567>.
It automatically creates a repository in the directory '.wiki'.

Dependencies
------------

- [ruby-git][]
- [HAML][]
- [RubyPants][]

Optional Dependencies
---------------------

- [RubyPants][] to fix puncation
- [Pygments][] for syntax highlighting
- [imaginator][] for LaTeX/graphviz output (minad-imaginator gem from github)
- [hpricot][] for tags in the wikitext
- [RMagick][] for image scaling and svg rendering

Dependencies for page rendering
-------------------------------

- [creole][] for creole wikitext rendering (minad-creole gem from github)
- [RDiscount][] for markdown rendering
- [RedCloth][] for textile rendering

At least one of the renderers should be installed.

  [ruby-git]: http://github.com/schacon/ruby-git
  [HAML]: http://haml.hamptoncatlin.com
  [RDiscount]: http://github.com/rtomayko/rdiscount
  [RedCloth]: http://whytheluckystiff.net/ruby/redcloth/
  [RubyPants]: http://chneukirchen.org/blog/static/projects/rubypants.html
  [creole]: http://github.com/minad/creole
  [imaginator]: http://github.com/minad/imaginator
  [pygments]: http://pygments.org/
  [hpricot]: http://wiki.github.com/why/hpricot
  [RMagick]: http://rmagick.rubyforge.org/

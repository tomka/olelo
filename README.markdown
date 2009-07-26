README
======

Git-Wiki is a a wiki that stores pages in a git repository.

Demo installation at <http://git-wiki.kicks-ass.org/>

Features
--------

A lot of the features are implemented as plugins.

- History
- Show diffs
- Edit page, upload files
- Section editing
- Plugin system
- Multiple renderers
- LaTeX/Graphviz
- Syntax highlighting (embedded code blocks)
- Image support, SVG support
- Auto-generated table of contents
- Templates
- XML tags can be used to extend Wiki syntax

Installation
------------

At first you have to install the gem dependencies via "gem".

    gem sources -a http://gems.github.org/
    gem install minad-creole
    gem install minad-git
    gem install minad-rack-esi
    gem install minad-mimemagic
    gem install rack-cache
    gem install haml
    gem install thin
    gem install rack

Optional:
    gem install hpricot
    gem install rdiscount
    gem install RedCloth
    gem install maruku
    gem install rubypants
    gem install rmagick
    gem install minad-imaginator
    gem install minad-evaluator

Then run with `./run.ru -sthin -p4567` and. point your browser at <http://localhost:4567>.
It automatically creates a repository in the directory '.wiki'. If you use ruby 1.9 it is very important
that you set the environment variable LANG to a UTF-8 locale. Otherwise you might get encoding exceptions.

For production purposes I recommend to deploy the wiki with thin and apache/nginx balancing.

    # Create thin config
    thin config -C thin.yml -s 3 -p 5000 -R run.ru -e deployment -d

    # Useful if you have multiple installations
    # export WIKI_CONFIG=/srv/wiki/config.yml

    # Start thin servers
    export LANG=en_US.UTF-8
    thin start -C thin.yml

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
- [RMagick][] for image scaling and svg rendering. RMagick is a ruby binding to the ImageMagick library. ImageMagick has to be installed.

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

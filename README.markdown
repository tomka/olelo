README
======

Git-Wiki is a wiki that stores pages in a [Git][] repository.

See the demo installation at <http://git-wiki.kicks-ass.org/>.

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

First, you have to install the [Gem][] dependencies via `gem`:

    gem sources -a http://gems.github.org/
    gem install minad-creole
    gem install minad-git
    gem install minad-rack-esi
    gem install minad-mimemagic
    gem install rack-cache
    gem install haml
    gem install thin
    gem install rack

### Optional:

    gem install hpricot
    gem install rdiscount
    gem install RedCloth
    gem install maruku
    gem install rubypants
    gem install minad-imaginator
    gem install minad-evaluator

Then, run the program using the command:

    ./run.ru -sthin -p4567

Point your web browser at <http://localhost:4567>.

### Notes:

Git-Wiki automatically creates a repository in the directory `./.wiki`.

If you use Ruby 1.9, it is very important that you set the environment
variable LANG to a UTF-8 locale. Otherwise, you might get encoding exceptions.

For production purposes, I recommend that you deploy the wiki
with Thin and Apache/nginx load balancing.

    # Create Thin config
    thin config -C thin.yml -s 3 -p 5000 -R run.ru -e deployment -d

    # Useful if you have multiple installations
    # export WIKI_CONFIG=/srv/wiki/config.yml

    # Start Thin servers
    export LANG=en_US.UTF-8
    thin start -C thin.yml

Dependencies
------------

- [HAML][]
- [ruby-git][]
- [RubyPants][]

### Optional Dependencies

- [hpricot][] for tags in the wikitext
- [imaginator][] for [LaTeX][]/[GraphViz][] output
  (`minad-imaginator` Gem from [GitHub][])
- [Pygments][] for syntax highlighting
- [ImageMagick][] for image scaling and svg rendering
- [RubyPants][] to fix punctuation

### Dependencies for page rendering

At least one of these renderers should be installed:

- [creole][] for creole wikitext rendering
  (`minad-creole` Gem from [GitHub][])
- [RDiscount][] for Markdown rendering
- [RedCloth][] for Textile rendering

[creole]:http://github.com/minad/creole
[Gem]:http://rubygems.org
[Git]:http://www.git-scm.org
[GitHub]:http://github.com
[GraphViz]:http://www.graphviz.org
[HAML]:http://haml.hamptoncatlin.com
[hpricot]:http://wiki.github.com/why/hpricot
[imaginator]:http://github.com/minad/imaginator
[LaTeX]:www.latex-project.org
[pygments]:http://pygments.org/
[RDiscount]:http://github.com/rtomayko/rdiscount
[RedCloth]:http://whytheluckystiff.net/ruby/redcloth/
[ImageMagick]:http://www.imagemagick.org/
[ruby-git]:http://github.com/schacon/ruby-git
[RubyPants]:http://chneukirchen.org/blog/static/projects/rubypants.html

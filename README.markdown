README
======

Git-Wiki is a wiki that stores pages in a [Git][] repository.

See the demo installation at <http://git.awiki.org/> or <http://git-wiki.kicks-ass.org/>.

Features
--------

A lot of the features are implemented as plugins.

- Edit, move or delete pages
- Support for hierarchical wikis (directory structure)
- Upload files
- History (also as RSS/Atom changelog)
- Plugin system
- Support for multiple text engines (Creole, Markdown, Textile, ...)
- Section editing for creole markup
- Embedded LaTeX/Graphviz graphics
- Syntax highlighting (embedded code blocks)
- Image resizing, SVG to bitmap conversion
- Auto-generated table of contents
- Templates via include-tag
- XML tag soup can be used to extend Wiki syntax
- View pages as S5 presentation

Installation
------------

First, you have to install the [Gem][] dependencies via `gem`:

    gem sources -a http://gemcutter.org
    gem install creole
    gem install gitrb
    gem install mimemagic
    gem install haml
    gem install rack
    gem install nokogiri
    gem install mongrel --source http://gems.rubyinstaller.org

    # other rack-esi implementations should also work
    # just try it
    gem install minad-rack-esi

    # this is a more current version of rack-cache with bugfixes
    # TODO: replace this with official release when new version is released
    gem install minad-rack-cache

### Optional:

    gem install rdiscount
    gem install RedCloth
    gem install maruku
    gem install rubypants
    gem install imaginator
    gem install evaluator
    gem install rack-embed
    gem install org-ruby

Then, run the program using the command:

    rackup -smongrel -p4567

Point your web browser at <http://localhost:4567>.

Git-Wiki automatically creates a repository in the directory `./.wiki`.
For production purposes, I recommend that you deploy the wiki with Mongrel.
I tested other webservers like unicorn, thin and webrick.
Git-Wiki works with all of them thanks to rack.

Configuration
-------------

You might want to deploy the wiki on a server and want to tweak some settings.
The default wiki configuration is in the file config.yml. You can specify
a different file via the environment variable WIKI_CONFIG.

    export WIKI_CONFIG=/home/user/wiki_config.yml

A documented example configuration is found at config.yml.sample.

Dependencies
------------

- [nokogiri][]
- [HAML][]
- [gitrb][]
- [rack][]
- [mimemagic][]

### Optional Dependencies

- [imaginator][] for [LaTeX][]/[GraphViz][] output
  (`imaginator` Gem from [gemcutter][])
- [Pygments][] for syntax highlighting
- [ImageMagick][] for image scaling and svg rendering
- [RubyPants][] to fix punctuation

### Dependencies for page rendering

At least one of these renderers should be installed:

- [creole][] for creole wikitext rendering
  (`creole` Gem from [gemcutter][])
- [RDiscount][] for Markdown rendering
- [RedCloth][] for Textile rendering
- [org-ruby][] for org-mode rendering

[creole]:http://github.com/minad/creole
[mimemagic]:http://github.com/minad/mimemagic
[Gem]:http://rubygems.org
[Git]:http://www.git-scm.org
[rack]:http://rack.rubyforge.org/
[org-ruby]:http://orgmode.org/worg/org-tutorials/org-ruby.php
[GraphViz]:http://www.graphviz.org
[HAML]:http://haml.hamptoncatlin.com
[nokogiri]:http://nokogiri.org/
[imaginator]:http://github.com/minad/imaginator
[LaTeX]:www.latex-project.org
[pygments]:http://pygments.org/
[RDiscount]:http://github.com/rtomayko/rdiscount
[RedCloth]:http://redcloth.org/
[ImageMagick]:http://www.imagemagick.org/
[gitrb]:http://github.com/minad/gitrb/
[gemcutter]:http://gemcutter.org/
[RubyPants]:http://chneukirchen.org/blog/static/projects/rubypants.html

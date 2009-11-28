SCRIPTS=$(wildcard static/script/*.js)
SASS_FILES=\
static/themes/blue/print.sass\
static/themes/blue/screen.sass\
plugins/treeview/treeview.sass\
plugins/misc/pygments.sass
CSS_FILES=$(SASS_FILES:.sass=.css)

all: static/script.js $(CSS_FILES)

css:
	rm -f $(CSS_FILES)
	make $(CSS_FILES)

clean:
	rm -f static/script.js $(CSS_FILES)

static/script.js: $(SCRIPTS)
	export CLASSPATH=$(CLASSPATH):tools/js.jar
	java -jar tools/shrinksafe.jar $^ > $@

%.css: %.sass
	sass -C -t compressed $^ $@

plugins/misc/pygments.sass:
	 pygmentize -S default -f html -a .highlight | css2sass > $@

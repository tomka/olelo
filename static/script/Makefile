SCRIPTS=$(wildcard *.js)

compress:
	rm -f all.js
	make all.js

all.js: $(SCRIPTS)
	export CLASSPATH=$CLASSPATH:../../tools/js.jar
	java -jar ../../tools/shrinksafe.jar $^ > $@

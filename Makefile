.PHONY: all build

all: build

build:
	haxe -cp src/ -main tppinputassist.Main -js script_build.js
	cat header.js > tppinputassist.user.js
	echo >> tppinputassist.user.js
	cat lib/jquery-2.1.4.min.js lib/jquery-ui-1.11.4.min.js >> tppinputassist.user.js
	echo >> tppinputassist.user.js
	cat script_build.js >> tppinputassist.user.js
	cat footer.js >> tppinputassist.user.js
	rm script_build.js


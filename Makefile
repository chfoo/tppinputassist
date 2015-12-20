.PHONY: all build

all: build

build:
	haxe -cp src/ -main tppinputassist.Main -js script_build.js
	cat header.js > tppinputassist.user.js
	cat script_build.js >> tppinputassist.user.js
	rm script_build.js


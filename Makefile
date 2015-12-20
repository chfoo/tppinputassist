.PHONY: all build

all: build

build:
	haxe -cp src/ -main tppinputassist.Main -js script_build.js
	cat header.js > script.js
	cat script_build.js >> script.js
	rm script_build.js


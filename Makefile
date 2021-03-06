.PHONY: all build

all: build

build:
	haxe build.hxml
	cat header.js > tppinputassist.user.js
	echo >> tppinputassist.user.js
	cat lib/jquery-3.2.0.min.js >> tppinputassist.user.js
	echo "var jQuery = $$.noConflict(true);" >> tppinputassist.user.js
	cat lib/jquery-ui-1.12.1.min.js | sed -r "s/(\\.)?ui-/\1tppia-ui-/g" >> tppinputassist.user.js
	echo >> tppinputassist.user.js
	cat script_build.js >> tppinputassist.user.js
	cat footer.js >> tppinputassist.user.js
	rm script_build.js

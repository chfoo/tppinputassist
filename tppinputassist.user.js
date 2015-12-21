// ==UserScript==
// @name         TPP Touchscreen Input Assist
// @namespace    chfoo/tppinputassist
// @version      1.1.1
// @homepage     https://github.com/chfoo/tppinputassist
// @updateURL    https://raw.githubusercontent.com/chfoo/tppinputassist/master/tppinputassist.user.js
// @description  Touchscreen coordinate tap overlay for inputting into Twitch chat
// @author       Christopher Foo
// @match        http://www.twitch.tv/*
// @grant        none
// ==/UserScript==
/* jshint -W097 */


(function (console, $global) { "use strict";
function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}
var HxOverrides = function() { };
HxOverrides.__name__ = true;
HxOverrides.cca = function(s,index) {
	var x = s.charCodeAt(index);
	if(x != x) return undefined;
	return x;
};
Math.__name__ = true;
var Reflect = function() { };
Reflect.__name__ = true;
Reflect.hasField = function(o,field) {
	return Object.prototype.hasOwnProperty.call(o,field);
};
Reflect.setField = function(o,field,value) {
	o[field] = value;
};
var Std = function() { };
Std.__name__ = true;
Std.string = function(s) {
	return js_Boot.__string_rec(s,"");
};
Std.parseInt = function(x) {
	var v = parseInt(x,10);
	if(v == 0 && (HxOverrides.cca(x,1) == 120 || HxOverrides.cca(x,1) == 88)) v = parseInt(x);
	if(isNaN(v)) return null;
	return v;
};
var js__$Boot_HaxeError = function(val) {
	Error.call(this);
	this.val = val;
	this.message = String(val);
	if(Error.captureStackTrace) Error.captureStackTrace(this,js__$Boot_HaxeError);
};
js__$Boot_HaxeError.__name__ = true;
js__$Boot_HaxeError.__super__ = Error;
js__$Boot_HaxeError.prototype = $extend(Error.prototype,{
	__class__: js__$Boot_HaxeError
});
var js_Boot = function() { };
js_Boot.__name__ = true;
js_Boot.getClass = function(o) {
	if((o instanceof Array) && o.__enum__ == null) return Array; else {
		var cl = o.__class__;
		if(cl != null) return cl;
		var name = js_Boot.__nativeClassName(o);
		if(name != null) return js_Boot.__resolveNativeClass(name);
		return null;
	}
};
js_Boot.__string_rec = function(o,s) {
	if(o == null) return "null";
	if(s.length >= 5) return "<...>";
	var t = typeof(o);
	if(t == "function" && (o.__name__ || o.__ename__)) t = "object";
	switch(t) {
	case "object":
		if(o instanceof Array) {
			if(o.__enum__) {
				if(o.length == 2) return o[0];
				var str2 = o[0] + "(";
				s += "\t";
				var _g1 = 2;
				var _g = o.length;
				while(_g1 < _g) {
					var i1 = _g1++;
					if(i1 != 2) str2 += "," + js_Boot.__string_rec(o[i1],s); else str2 += js_Boot.__string_rec(o[i1],s);
				}
				return str2 + ")";
			}
			var l = o.length;
			var i;
			var str1 = "[";
			s += "\t";
			var _g2 = 0;
			while(_g2 < l) {
				var i2 = _g2++;
				str1 += (i2 > 0?",":"") + js_Boot.__string_rec(o[i2],s);
			}
			str1 += "]";
			return str1;
		}
		var tostr;
		try {
			tostr = o.toString;
		} catch( e ) {
			if (e instanceof js__$Boot_HaxeError) e = e.val;
			return "???";
		}
		if(tostr != null && tostr != Object.toString && typeof(tostr) == "function") {
			var s2 = o.toString();
			if(s2 != "[object Object]") return s2;
		}
		var k = null;
		var str = "{\n";
		s += "\t";
		var hasp = o.hasOwnProperty != null;
		for( var k in o ) {
		if(hasp && !o.hasOwnProperty(k)) {
			continue;
		}
		if(k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" || k == "__properties__") {
			continue;
		}
		if(str.length != 2) str += ", \n";
		str += s + k + " : " + js_Boot.__string_rec(o[k],s);
		}
		s = s.substring(1);
		str += "\n" + s + "}";
		return str;
	case "function":
		return "<function>";
	case "string":
		return o;
	default:
		return String(o);
	}
};
js_Boot.__interfLoop = function(cc,cl) {
	if(cc == null) return false;
	if(cc == cl) return true;
	var intf = cc.__interfaces__;
	if(intf != null) {
		var _g1 = 0;
		var _g = intf.length;
		while(_g1 < _g) {
			var i = _g1++;
			var i1 = intf[i];
			if(i1 == cl || js_Boot.__interfLoop(i1,cl)) return true;
		}
	}
	return js_Boot.__interfLoop(cc.__super__,cl);
};
js_Boot.__instanceof = function(o,cl) {
	if(cl == null) return false;
	switch(cl) {
	case Int:
		return (o|0) === o;
	case Float:
		return typeof(o) == "number";
	case Bool:
		return typeof(o) == "boolean";
	case String:
		return typeof(o) == "string";
	case Array:
		return (o instanceof Array) && o.__enum__ == null;
	case Dynamic:
		return true;
	default:
		if(o != null) {
			if(typeof(cl) == "function") {
				if(o instanceof cl) return true;
				if(js_Boot.__interfLoop(js_Boot.getClass(o),cl)) return true;
			} else if(typeof(cl) == "object" && js_Boot.__isNativeObj(cl)) {
				if(o instanceof cl) return true;
			}
		} else return false;
		if(cl == Class && o.__name__ != null) return true;
		if(cl == Enum && o.__ename__ != null) return true;
		return o.__enum__ == cl;
	}
};
js_Boot.__cast = function(o,t) {
	if(js_Boot.__instanceof(o,t)) return o; else throw new js__$Boot_HaxeError("Cannot cast " + Std.string(o) + " to " + Std.string(t));
};
js_Boot.__nativeClassName = function(o) {
	var name = js_Boot.__toStr.call(o).slice(8,-1);
	if(name == "Object" || name == "Function" || name == "Math" || name == "JSON") return null;
	return name;
};
js_Boot.__isNativeObj = function(o) {
	return js_Boot.__nativeClassName(o) != null;
};
js_Boot.__resolveNativeClass = function(name) {
	return $global[name];
};
var tppinputassist_ElementNotFoundError = function() {
};
tppinputassist_ElementNotFoundError.__name__ = true;
tppinputassist_ElementNotFoundError.prototype = {
	__class__: tppinputassist_ElementNotFoundError
};
var tppinputassist_App = function() {
	this.touchscreenHeight = 240;
	this.touchscreenWidth = 320;
};
tppinputassist_App.__name__ = true;
tppinputassist_App.prototype = {
	run: function() {
		var _g = this;
		js.JQuery(window.document.body).ready(function(event) {
			console.log("Page loaded, trying install script");
			_g.jamJQueryIn();
		});
	}
	,jamJQueryIn: function() {
		var _g = this;
		js.JQuery.getScript("https://code.jquery.com/ui/1.11.4/jquery-ui.min.js",function() {
			_g.installSettingsButton();
		});
		var div;
		div = js_Boot.__cast(window.document.createElement("div") , HTMLDivElement);
		div.innerHTML = "\n            <link rel='stylesheet' href='https://code.jquery.com/ui/1.11.4/themes/dark-hive/jquery-ui.css' type='text/css'>\n        ";
		window.document.body.appendChild(div);
	}
	,installSettingsButton: function() {
		var _g = this;
		var buttonContainer = window.document.querySelector(".chat-buttons-container");
		this.throwIfNull(buttonContainer);
		var enableElement;
		enableElement = js_Boot.__cast(window.document.createElement("a") , HTMLAnchorElement);
		enableElement.textContent = "TPPInputAssist";
		enableElement.href = "#";
		enableElement.onclick = function(event) {
			if(_g.settingsPanel == null) _g.install();
			var jq = js.JQuery(_g.settingsPanel);
			jq.dialog({ 'title' : "TPP Input Assist Settings"});
			return false;
		};
		buttonContainer.appendChild(enableElement);
	}
	,install: function() {
		var element;
		element = window.document.querySelector(".chat_text_input");
		this.throwIfNull(element);
		this.textarea = js_Boot.__cast(element , HTMLTextAreaElement);
		this.installSettingsPanel();
		this.installTouchscreenOverlay();
	}
	,throwIfNull: function(element) {
		if(element == null) throw new js__$Boot_HaxeError(new tppinputassist_ElementNotFoundError());
	}
	,installSettingsPanel: function() {
		var _g = this;
		this.settingsPanel = js_Boot.__cast(window.document.createElement("div") , HTMLDivElement);
		this.settingsPanel.style.display = "none";
		this.settingsPanel.innerHTML = "\n            <fieldset>\n            <legend>Touchscreen</legend>\n            <label for=tpp_assist_enable_checkbox\n                style='margin: inherit; color: inherit; display: inline-block'\n            >\n                <input type=checkbox id=tpp_assist_enable_checkbox>\n                Enable tap overlay\n            </label>\n            <br>\n            Width: <input id=tpp_assist_width_input type=number min=0 value=320 style='width: 5em;'>\n            <br>\n            Height: <input id=tpp_assist_height_input type=number min=0 value=240 style='width: 5em;'>\n            </fieldset>\n        ";
		window.document.body.appendChild(this.settingsPanel);
		var enableCheckbox;
		enableCheckbox = js_Boot.__cast(window.document.getElementById("tpp_assist_enable_checkbox") , HTMLInputElement);
		enableCheckbox.onclick = function(event) {
			_g.showTouchscreenOverlay(enableCheckbox.checked);
		};
		var widthInput;
		widthInput = js_Boot.__cast(window.document.getElementById("tpp_assist_width_input") , HTMLInputElement);
		var heightInput;
		heightInput = js_Boot.__cast(window.document.getElementById("tpp_assist_width_input") , HTMLInputElement);
		widthInput.onchange = heightInput.onchange = function(event1) {
			_g.touchscreenWidth = Std.parseInt(widthInput.value);
			_g.touchscreenHeight = Std.parseInt(heightInput.value);
		};
	}
	,installTouchscreenOverlay: function() {
		var _g = this;
		this.touchScreenOverlay = js_Boot.__cast(window.document.createElement("div") , HTMLDivElement);
		this.touchScreenOverlay.style.border = "0.1em solid grey";
		this.touchScreenOverlay.style.zIndex = "99";
		this.touchScreenOverlay.style.width = "100px";
		this.touchScreenOverlay.style.height = "100px";
		this.touchScreenOverlay.style.display = "none";
		this.touchScreenOverlay.style.position = "absolute";
		var dragHandle;
		dragHandle = js_Boot.__cast(window.document.createElement("div") , HTMLDivElement);
		this.touchScreenOverlay.appendChild(dragHandle);
		dragHandle.style.border = "0.1em outset grey";
		dragHandle.style.position = "relative";
		dragHandle.style.top = "-0.5em";
		dragHandle.style.left = "-0.5em";
		dragHandle.style.background = "grey";
		dragHandle.style.height = "1em";
		dragHandle.style.cursor = "move";
		dragHandle.style.opacity = "0.5";
		dragHandle.style.color = "white";
		var clickReceiver;
		clickReceiver = js_Boot.__cast(window.document.createElement("div") , HTMLDivElement);
		this.touchScreenOverlay.appendChild(clickReceiver);
		clickReceiver.style.width = "100%";
		clickReceiver.style.height = "100%";
		window.document.body.appendChild(this.touchScreenOverlay);
		js.JQuery(clickReceiver).click(function(event) {
			var coord = _g.calcCoordinate(event);
			js.JQuery(_g.textarea).focus().val("" + coord.x + "," + coord.y);
		});
		js.JQuery(clickReceiver).mousemove(function(event1) {
			var coord1 = _g.calcCoordinate(event1);
			dragHandle.innerText = "" + coord1.x + "," + coord1.y;
		});
		js.JQuery(clickReceiver).mouseleave(function(event2) {
			dragHandle.innerText = "";
		});
		var jq = js.JQuery(this.touchScreenOverlay);
		jq.draggable({ 'handle' : dragHandle}).resizable();
	}
	,calcCoordinate: function(event) {
		var offset = js.JQuery(this.touchScreenOverlay).offset();
		var divWidth = js.JQuery(this.touchScreenOverlay).width();
		var divHeight = js.JQuery(this.touchScreenOverlay).height();
		var x = (event.pageX - offset.left) / divWidth * this.touchscreenWidth | 0;
		var y = (event.pageY - offset.top) / divHeight * this.touchscreenHeight | 0;
		return { x : x, y : y};
	}
	,showTouchscreenOverlay: function(visible) {
		var offset = js.JQuery("#player").offset();
		var top = "50px";
		var left = "50px";
		if(offset != null) {
			left = "" + (offset.left + 30) + "px";
			top = "" + (offset.top + 30) + "px";
		}
		if(visible) {
			this.touchScreenOverlay.style.display = "block";
			this.touchScreenOverlay.style.top = top;
			this.touchScreenOverlay.style.left = left;
		} else this.touchScreenOverlay.style.display = "none";
	}
	,__class__: tppinputassist_App
};
var tppinputassist_Main = function() { };
tppinputassist_Main.__name__ = true;
tppinputassist_Main.main = function() {
	if(Reflect.hasField(window.document,tppinputassist_Main.NAMESPACE)) return;
	Reflect.setField(window.document,tppinputassist_Main.NAMESPACE,true);
	var app = new tppinputassist_App();
	app.run();
};
String.prototype.__class__ = String;
String.__name__ = true;
Array.__name__ = true;
var Int = { __name__ : ["Int"]};
var Dynamic = { __name__ : ["Dynamic"]};
var Float = Number;
Float.__name__ = ["Float"];
var Bool = Boolean;
Bool.__ename__ = ["Bool"];
var Class = { __name__ : ["Class"]};
var Enum = { };
var q = window.jQuery;
var js = js || {}
js.JQuery = q;
js_Boot.__toStr = {}.toString;
tppinputassist_Main.NAMESPACE = "tppinputassist";
tppinputassist_Main.main();
})(typeof console != "undefined" ? console : {log:function(){}}, typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);

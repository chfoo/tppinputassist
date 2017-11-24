TPP Touchscreen Input Assist
============================


Usage
=====

You will either need [Greasemonkey](https://addons.mozilla.org/firefox/addon/greasemonkey/) or [Tampermonkey](https://tampermonkey.net/) desktop browser extensions. Once those are installed, click or use this URL: https://raw.githubusercontent.com/chfoo/tppinputassist/master/tppinputassist.user.js. (If that URL does not work, use [this one](https://nullhound.fart.website/~chris/tppinputassist/tppinputassist.user.js).)

(Alternatively, you can use bookmarklet: `javascript:(function(){document.body.appendChild(document.createElement('script')).src='https://nullhound.fart.website/~chris/tppinputassist/tppinputassist.user.js';})();` . May not work; recommended to use the browser extensions.)

Once enabled, reload the video page. Wait at least 10 seconds. The Twitch chat will show "TPPInputAssist" under the text box. Click it to show the settings panel.

When you enable the touchscreen feature, a box will appear on the video. Drag the box over the touchscreen portion of the video using the top handlebar. Then use the bottom handlebar to resize it. When you click within the box, the coordinates will appear in the chat text box.

Due to problems with Twitch using What-Input, sending messages and auto-sending messages is **broken**. You need to **add a space to your message** before it recognizes that the textbox has text. Also, **don't use theater mode**; it will cover up the touchscreen.

The DS uses a 256×192 pixel touchscreen and the 3DS uses 320×240 touchscreen. Be sure to adjust the size setting if needed.

If you notice any visual or functional anomalies with Twitch page or extensions (such as BTTV or FFZ), please file a bug report and temporary disable/enable extensions as needed.

Compiling
=========

To compile the script on Linux, install Haxe 3.4. Then run the makefile with `make` and the JavaScript output will be in the same directory.

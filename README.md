TPP Touchscreen Input Assist
============================


Usage
=====

You will either need [Greasemonkey](https://addons.mozilla.org/firefox/addon/greasemonkey/) or [Tampermonkey](https://tampermonkey.net/) desktop browser extensions. Once those are installed, click or use this URL: https://raw.githubusercontent.com/chfoo/tppinputassist/master/tppinputassist.user.js. (If that URL does not work, use [this one](https://nullhound.fart.website/~chris/tppinputassist/tppinputassist.user.js).)

(Alternatively, you can use bookmarklet: `javascript:(function(){document.body.appendChild(document.createElement('script')).src='https://nullhound.fart.website/~chris/tppinputassist/tppinputassist.user.js';})();` . This will work until you leave the page.)

Once enabled in Greasemoney/Tampermonkey, reload the video page. Wait at least 10 seconds. The Twitch chat will show "TPPInputAssist" under the text box. Click it to show the settings panel.

When you enable the touchscreen feature, a box will appear on the video. Drag the box over the touchscreen portion of the video using the top handlebar. Then use the bottom handlebar to resize it. When you click within the box, the coordinates will appear in the chat text box.

The DS uses a 256×192 pixel touchscreen and the 3DS uses 320×240 touchscreen. Be sure to adjust the size setting if needed.

The overlay might not work correctly on all views or pages using the new Twitch layout. Particularly, fullscreen may hide the overlay and whispers boxes may be covered.

If you notice any visual or functional anomalies affecting extensions (such as BTTV or FFZ), please file a bug report and temporary disable/enable extensions as needed.

Compiling
=========

(This instruction is for users who wish to compare the precompiled script with the source code.)

To compile the script on Linux, install Haxe 3.4. Then run the makefile with `make` and the JavaScript output will be in the same directory.

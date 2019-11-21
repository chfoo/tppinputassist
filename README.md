# TPP Touchscreen Input Assist

User script for helping a player create and send inputs into a Twitch Plays channel text chat box. It provides a touchscreen coordinate tap overlay for precise touchscreen inputs. It is not tied to any specific game or channel.

This script does not support automation (botting). Check the broadcaster's chat rules before using this script.

## Usage

You will either need [Greasemonkey](https://addons.mozilla.org/firefox/addon/greasemonkey/) or [Tampermonkey](https://tampermonkey.net/) desktop browser extensions. Once those are installed, click or use this URL: https://raw.githubusercontent.com/chfoo/tppinputassist/master/tppinputassist.user.js. (If that URL does not work, use [this one](https://nullhound.fart.website/~chris/tppinputassist/tppinputassist.user.js).)

(Alternatively, you can use bookmarklet: `javascript:(function(){document.body.appendChild(document.createElement('script')).src='https://nullhound.fart.website/~chris/tppinputassist/tppinputassist.user.js';})();` . This will work until you leave the page.)

Once enabled in Greasemoney/Tampermonkey, reload the video page. Wait at least 10 seconds. The Twitch chat will show "TPPInputAssist" under the text box. Click it to show the settings panel.

When you enable the touchscreen feature, a box will appear on the video. Drag the box over the touchscreen portion of the video using the top handlebar. Then use the bottom handlebar to resize it. When you click within the box, the coordinates will appear in the chat text box.

The DS uses a 256×192 pixel touchscreen, the 3DS uses 320×240 touchscreen, and the Switch uses a 1280x720 touchscreen. Be sure to adjust the size setting if needed.

The overlay might not work correctly on all views or pages using the new Twitch layout. Particularly, fullscreen may hide the overlay and whispers boxes may be covered.

If you notice any visual or functional anomalies affecting extensions (such as BTTV or FFZ), please file a bug report and temporary disable/enable extensions as needed.

### Gamepad

This script includes gamepad support using HTML5 Gamepad API just for fun.

To use a gamepad, you will need a modern web browser and a gamepad that supports the ["standard" mapping](https://w3c.github.io/gamepad/#remapping) such as Xbox or Playstation controller. You can go to [HTML5 Gamepad Tester](https://html5gamepad.com/) and check that it shows up as standard mapping with 4 axis (2 sticks) and buttons 0-16 (17 buttons). If the gamepad mapping is wrong, try a different web browser.

Table of button mappings in standard mapping:

| Button/Axis ID | Generic | Xbox | PS | Switch | TPP |
|----------------|---------|------|----|--------|-----|
| button[0] | Button 1 | A | Cross | A | a |
| button[1] | Button 2 | B | Circle | B | b |
| button[2] | Button 3 | X | Square | X  | x |
| button[3] | Button 4 | Y | Triangle | Y | y |
| button[4] | Shoulder Left | LB | L1 | L | l |
| button[5] | Shoulder Right | RB | R1 | R | r |
| button[6] | Shoulder Left 2 | LT | L2 | ZL | l2/zl |
| button[7] | Shoulder Right 2 | RT | R2 | ZR | r2/zr |
| button[8] | Back | View | Share | - | select/select |
| button[9] | Forward/Home | Menu | Options | + | start/plus |
| button[10] | Left-stick Press | " | L3 | " | l3/lstick |
| button[11] | Right-stick press | " | R3 | " | r3/rstick |
| button[12] | D-Pad Up | " | " | " | dup |
| button[13] | D-Pad Down | " | " | " | ddown |
| button[14] | D-Pad Left | " | " | " | dleft |
| button[15] | D-Pad Right | " | " | " | dright |
| button[16] | Home/Power | Xbox | PS | Home | Kappa |
| - axis[0] | Left-stick Left | " | " | " | left/w |
| + axis[0] | Left-stick Right | " | " | " | right/e |
| - axis[1] | Left-stick Up | " | " | " | up/n |
| + axis[1] | Left-stick Down | " | " | " | down/s |
| - axis[2] | Right-stick Left | " | " | " | cleft/rleft |
| + axis[2] | Right-stick Right | " | " | " | cright/rright |
| - axis[3] | Right-stick Up | " | " | " | cup/rup |
| + axis[3] | Right-stick Down | " | " | " | cdown/rdown |

Be sure to configure the correct input text.

To send buttons as text chat inputs, press the button or tilt a thumb stick on the gamepad and release it. You can press up to 3 inputs (chording). Make sure that you release all the buttons at the same time and the script will combine the buttons using "+" such as "b+down".

If you press more than 3 and release at the same time, the script will ignore it. This is useful if you begin to press a button by accident.

## Compiling

(This instruction is for users who wish to compare the precompiled script with the source code. You don't need to compile it yourself just to use the script.)

To compile the script on Linux, install Haxe 4.0. Then run the makefile with `make` and the JavaScript output will be in the same directory.

## FAQ

**Q. Why doesn't the channel use Twitch extensions?**

A. Using Twitch extensions is certainly possible and a carefully designed extension will work well in a Twitch Plays. However in the case of Twitch Plays Pokemon, games are carefully picked to avoid requiring precise touchscreen inputs especially for those on mobile devices. Aliases mapped to specific common points on the touchscreen can be used as inputs too. As well, Twitch extensions only provide broadcasters a masked ID for each user.

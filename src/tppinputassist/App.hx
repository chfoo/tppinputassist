package tppinputassist;

import haxe.Json;
import js.html.ButtonElement;
import js.JQuery;
import js.html.InputElement;
import js.html.Event;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.Element;
import js.html.TextAreaElement;
import js.Browser;

using StringTools;


typedef XY = {
    x:Int, y:Int
};


class ElementNotFoundError {
    public function new() {
    }
}


class App {
    var running = false;
    var textarea:TextAreaElement;
    var touchScreenOverlay:DivElement;
    var settingsPanel:DivElement;
    var autoSendCheckbox:InputElement;
    var sendButton:ButtonElement;
    var coordDisplay:DivElement;
    var widthInput:InputElement;
    var heightInput:InputElement;
    var formatElement:InputElement;
    var touchscreenWidth = 320;
    var touchscreenHeight = 240;
    var touchscreenFormat = "{x},{y}";
    var lastSendTime:Date;

    public function new() {
        lastSendTime = Date.now();
    }

    public function run() {
        trace("TPPInputAssist script run", Browser.window.location);

        attachLoadHook();
    }

    function detectButtonContainer():Bool {
        var buttonContainer:Element = Browser.document.querySelector(".chat-buttons-container");

        return buttonContainer != null;
    }

    function attachLoadHook() {
        new JQuery(Browser.document.body).ready(function(event:JqEvent) {
            if (running) {
                return;
            }

            running = true;
            trace("Page loaded, trying install script");

            Browser.window.setTimeout(jamJQueryIn, 2000);
        });
    }

    function jamJQueryIn() {
        if (!detectButtonContainer()) {
            trace("Button container not found, exiting.");
            return;
        }

        trace("Installing settings button");
        installSettingsButton();

        var style = Browser.document.createStyleElement();
        style.textContent = CSS.getCSS();
        Browser.document.body.appendChild(style);
    }

    function installSettingsButton() {
        var buttonContainer:Element = Browser.document.querySelector(".chat-buttons-container");

        throwIfNull(buttonContainer);

        var enableElement = Browser.document.createAnchorElement();
        enableElement.textContent = "TPPInputAssist";
        enableElement.href = "#";
        enableElement.onclick = function (event:Dynamic) {
            if (settingsPanel == null) {
                install();
            }

            var jq = new JQuery(settingsPanel);
            untyped jq.dialog({"title": "TPP Input Assist Settings"});
            return false;
        }

        buttonContainer.appendChild(enableElement);
    }

    function install() {
        var element:Element;

        element = Browser.document.querySelector(".chat-interface .chat_text_input");
        throwIfNull(element);
        textarea = cast(element, TextAreaElement);

        installSettingsPanel();
        installTouchscreenOverlay();
        loadSettings();
    }

    function throwIfNull(element:Element) {
        if (element == null) {
            throw new ElementNotFoundError();
        }
    }

    function installSettingsPanel() {
        settingsPanel = Browser.document.createDivElement();
        settingsPanel.classList.add("tpp-input-assist");
        settingsPanel.style.display = "none";

        // The label has inline styles to override the Twitch CSS
        settingsPanel.innerHTML = "
            <fieldset>
            <legend>Touchscreen</legend>
            <label for=tpp_assist_enable_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_enable_checkbox>
                Enable tap overlay
            </label>
            <label for=tpp_assist_auto_send_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_auto_send_checkbox>
                Automatically Send on click
            </label>
            <br>
            Width: <input id=tpp_assist_width_input type=number min=0 value=320 style='width: 5em;'>
            <br>
            Height: <input id=tpp_assist_height_input type=number min=0 value=240 style='width: 5em;'>
            <br>
            Format: <input id=tpp_assist_format_input type=text value='{x},{y}' style='width: 5em;'>
            <br>
            <label for=tpp_assist_avoid_ban_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_avoid_ban_checkbox checked=checked>
                Don't autosend if clicked too fast (helps avoid global ban)
            </label>
            </fieldset>
        ";

        Browser.document.body.appendChild(settingsPanel);

        var enableCheckbox = cast(Browser.document.getElementById("tpp_assist_enable_checkbox"), InputElement);
        enableCheckbox.onclick = function (event:Event) {
            showTouchscreenOverlay(enableCheckbox.checked);
            loadSettings();
        }

        var element = Browser.document.getElementById("tpp_assist_auto_send_checkbox");
        throwIfNull(element);
        autoSendCheckbox = cast(element, InputElement);

        element = Browser.document.querySelector("div.chat-buttons-container > button.js-chat-buttons__submit");
        throwIfNull(element);
        sendButton = cast(element, ButtonElement);

        widthInput = cast(Browser.document.getElementById("tpp_assist_width_input"), InputElement);
        heightInput = cast(Browser.document.getElementById("tpp_assist_height_input"), InputElement);

        widthInput.onchange = heightInput.onchange = function(event:Event) {
            touchscreenWidth = Std.parseInt(widthInput.value);
            touchscreenHeight = Std.parseInt(heightInput.value);
            saveSettings();
        }

        formatElement = cast(Browser.document.getElementById("tpp_assist_format_input"), InputElement);
        formatElement.onchange = function(event:Event) {
            touchscreenFormat = formatElement.value;
            saveSettings();
        }
    }

    function installTouchscreenOverlay() {
        touchScreenOverlay = Browser.document.createDivElement();
        touchScreenOverlay.classList.add("tpp-input-assist");
        touchScreenOverlay.style.border = "0.1em solid grey";
        touchScreenOverlay.style.zIndex = "99";
        touchScreenOverlay.style.width = "100px";
        touchScreenOverlay.style.height = "100px";
        touchScreenOverlay.style.display = "none";
        touchScreenOverlay.style.position = "absolute";

        coordDisplay = Browser.document.createDivElement();
        touchScreenOverlay.appendChild(coordDisplay);
        coordDisplay.style.position = "absolute";
        coordDisplay.style.bottom = "0px";
        coordDisplay.style.left = "0px";
        coordDisplay.style.opacity = "0.75";
        coordDisplay.style.color = "white";
        coordDisplay.style.fontSize = "0.75em";
        coordDisplay.style.width = "100%";
        coordDisplay.textContent = "Drag & Size Me";
        coordDisplay.style.textShadow = "0px 0px 3px black";

        var clickReceiver = Browser.document.createDivElement();
        touchScreenOverlay.appendChild(clickReceiver);
        clickReceiver.style.position = "absolute";
        clickReceiver.style.top = "0px";
        clickReceiver.style.width = "100%";
        clickReceiver.style.height = "100%";
        clickReceiver.style.cursor = "crosshair";

        var dragHandle = Browser.document.createDivElement();
        touchScreenOverlay.appendChild(dragHandle);
        dragHandle.style.border = "0.1em outset grey";
        dragHandle.style.position = "relative";
        dragHandle.style.top = "-0.5em";
        dragHandle.style.left = "-0.5em";
        dragHandle.style.background = "grey";
        dragHandle.style.height = "1em";
        dragHandle.style.cursor = "move";
        dragHandle.style.opacity = "0.5";
        dragHandle.style.color = "white";

        Browser.document.body.appendChild(touchScreenOverlay);

        new JQuery(clickReceiver).click(function (event:JqEvent) {
            var coord = calcCoordinate(event);
            var text = touchscreenFormat
                .replace("{x}", Std.string(coord.x))
                .replace("{y}", Std.string(coord.y));
            new JQuery(textarea).focus().val(text);

            coordDisplay.textContent = '${coord.x},${coord.y} *';

            if (autoSendCheckbox.checked) {
                var dateNow = Date.now();

                var element = Browser.document.getElementById("tpp_assist_avoid_ban_checkbox");
                throwIfNull(element);
                var avoidBanCheckbox = cast(element, InputElement);

                if (dateNow.getTime() - lastSendTime.getTime() < 1.5 * 1000 && avoidBanCheckbox.checked) {
                    coordDisplay.textContent += " Slow down! Msg not sent";
                    return;
                }

                lastSendTime = dateNow;

                new JQuery(sendButton).focus();
                new JQuery(textarea).focus();
                new JQuery(sendButton).click();
            }
        });

        new JQuery(clickReceiver).mousemove(function (event:JqEvent) {
            var coord = calcCoordinate(event);
            coordDisplay.textContent = '${coord.x},${coord.y}';
        });

        new JQuery(clickReceiver).mouseleave(function (event:JqEvent) {
            coordDisplay.textContent = "";
        });

        var jq = new JQuery(touchScreenOverlay);
        untyped jq.draggable({handle: dragHandle})
            .resizable({
                stop: function (event: Event, ui: Dynamic) {
                    saveSettings();
            }
        });
    }

    function calcCoordinate(event:JqEvent):XY {
        var offset = new JQuery(touchScreenOverlay).offset();
        var divWidth = new JQuery(touchScreenOverlay).width();
        var divHeight = new JQuery(touchScreenOverlay).height();
        var x = Std.int((event.pageX - offset.left) / divWidth * touchscreenWidth);
        var y = Std.int((event.pageY - offset.top) / divHeight * touchscreenHeight);

        return {x: x, y: y};
    }

    function showTouchscreenOverlay(visible:Bool) {
        var offset = new JQuery("#player").offset();
        var top = "50px";
        var left = "50px";

        if (offset != null) {
            left = '${offset.left + 30}px';
            top = '${offset.top + 30}px';
        }

        if (visible) {
            touchScreenOverlay.style.display = "block";
            touchScreenOverlay.style.top = top;
            touchScreenOverlay.style.left = left;
        } else {
            touchScreenOverlay.style.display = "none";
        }
    }

    function loadSettings() {
        var docString = Browser.window.localStorage.getItem(
            'tppinputassist-${Browser.window.location.pathname}-settings');
        if (docString == null) {
            return;
        }

        var doc = Json.parse(docString);

        widthInput.value = Std.string(touchscreenWidth = Reflect.field(doc, "width"));
        heightInput.value = Std.string(touchscreenHeight = Reflect.field(doc, "height"));
        formatElement.value = touchscreenFormat = Reflect.field(doc, "format");

        touchScreenOverlay.style.width = Reflect.field(doc, "overlayWidth");
        touchScreenOverlay.style.height = Reflect.field(doc, "overlayHeight");
    }

    function saveSettings() {
        var doc = {
            width: widthInput.value,
            height: heightInput.value,
            format: formatElement.value,
            overlayWidth: touchScreenOverlay.style.width,
            overlayHeight: touchScreenOverlay.style.height
        };

        Browser.window.localStorage.setItem(
            'tppinputassist-${Browser.window.location.pathname}-settings',
            Json.stringify(doc)
        );
    }
}

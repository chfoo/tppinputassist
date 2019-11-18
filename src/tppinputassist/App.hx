package tppinputassist;

import haxe.DynamicAccess;
import haxe.Json;
import js.Browser;
import js.html.ButtonElement;
import js.html.DivElement;
import js.html.Element;
import js.html.Event;
import js.html.InputElement;
import js.html.TextAreaElement;
import js.jquery.JQuery;

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
    var avoidBanCheckbox:InputElement;
    var sendButton:ButtonElement;
    var coordDisplay:DivElement;
    var widthInput:InputElement;
    var heightInput:InputElement;
    var formatElement:InputElement;
    var touchscreenWidth = 320;
    var touchscreenHeight = 240;
    var touchscreenFormat = "{x},{y}";
    var lastSendTime:Date;
    var lastSendText = "";
    final gamepadButtonFormatInputs:Array<InputElement>;
    final gamepadHandler:GamepadHandler;

    static final gamepadButtonIds = [
        "button1",
        "button2",
        "button3",
        "button4",
        "shoulder_left",
        "shoulder_right",
        "shoulder_left2",
        "shoulder_right2",
        "select",
        "start",
        "left_stick_press",
        "right_stick_press",
        "dpad_up",
        "dpad_down",
        "dpad_left",
        "dpad_right",
        "home",
        "left_stick_left",
        "left_stick_right",
        "left_stick_up",
        "left_stick_down",
        "right_stick_left",
        "right_stick_right",
        "right_stick_up",
        "right_stick_down"
    ];
    static final gamepadButtonLabels = [
        "Button 1 (A/Cross)",
        "Button 2 (B/Circle)",
        "Button 3 (X/Square)",
        "Button 4 (Y/Triangle)",
        "Shoulder Left (L)",
        "Shoulder Right (R)",
        "Shoulder Left 2 (ZL/L2)",
        "Shoulder Right 2 (ZR/R2)",
        "Select (Back/View/-)",
        "Start (Fwd/Menu/+)",
        "Left stick press (L3)",
        "Right stick press (R3)",
        "D-Pad Up (dup)",
        "D-Pad Down (ddown)",
        "D-Pad Left (dleft)",
        "D-Pad Right (dright)",
        "Home (Power/Xbox/PS)",
        "Left-stick Left",
        "Left-stick Right",
        "Left-stick Up",
        "Left-stick Down",
        "Right-stick Left (cleft)",
        "Right-stick Right (cright)",
        "Right-stick Up (cup)",
        "Right-stick Down (cdown)"
    ];
    static final gamepadButtonDefaults = [
        "a",
        "b",
        "x",
        "y",
        "l",
        "r",
        "zl",
        "zr",
        "select",
        "start",
        "l3",
        "r3",
        "dup",
        "ddown",
        "dleft",
        "dright",
        "home",
        "left",
        "right",
        "up",
        "down",
        "cleft",
        "cright",
        "cup",
        "cdown"
    ];

    public function new() {
        lastSendTime = Date.now();
        gamepadButtonFormatInputs = [];
        gamepadHandler = new GamepadHandler();
    }

    public function run() {
        trace("TPPInputAssist script run", Browser.window.location);

        attachLoadHook();
    }

    function detectButtonContainer():Bool {
        var buttonContainer:Element = Browser.document.querySelector(".chat-input__buttons-container");

        return buttonContainer != null;
    }

    function attachLoadHook() {
        new JQuery(Browser.document.body).ready(function(event:js.jquery.Event) {
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
        var buttonContainer:Element = null;

        buttonContainer = Browser.document.querySelector(".chat-input__buttons-container > div.tw-flex-row");

        throwIfNull(buttonContainer);

        var enableElement = Browser.document.createAnchorElement();
        enableElement.textContent = "TPPInputAssist";
        enableElement.href = "#";
        enableElement.onclick = function (event:Dynamic) {
            if (settingsPanel == null) {
                install();
            }

            var jq = new JQuery(settingsPanel);
            untyped jq.dialog({"title": "TPP Input Assist Settings", "width": 400, "height": 300});
            untyped jq.dialog("widget").css("z-index", "3002");
            return false;
        }

        buttonContainer.appendChild(enableElement);
    }

    function install() {
        var element:Element;

        element = Browser.document.querySelector(".chat-input textarea[data-a-target='chat-input']");

        throwIfNull(element);
        textarea = cast(element, TextAreaElement);

        installSettingsPanel();
        installTouchscreenOverlay();
        loadSettings();

        gamepadHandler.onInput = gamepadInputCallback;
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
        final panelHTMLBuf = new StringBuf();
        panelHTMLBuf.add("
            <fieldset style='border: 1px solid gray; padding: 0.25em'>
            <legend>Touchscreen</legend>
            <label for=tpp_assist_enable_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_enable_checkbox>
                Enable tap overlay
            </label>

            <br>
            <label>Width: <input id=tpp_assist_width_input type=number min=0 value=320 style='width: 5em;'></label>
            <br>
            <label>Height: <input id=tpp_assist_height_input type=number min=0 value=240 style='width: 5em;'></label>
            <br>
            <label>Format: <input id=tpp_assist_format_input type=text value='{x},{y}' style='width: 5em;'></label>
            </fieldset>");

        panelHTMLBuf.add("
            <fieldset style='border: 1px solid gray; padding: 0.25em'>
            <legend>Gamepad</legend>
            <label for=tpp_assist_gamepad_enable_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'>
                <input type=checkbox id=tpp_assist_gamepad_enable_checkbox>
                Enable gamepad input
            </label>
            <details>
                <summary>Button-input mappings</summary>
        ");

        for (index in 0...25) {
            final label = gamepadButtonLabels[index];
            final id = gamepadButtonIds[index];
            final defaultValue = gamepadButtonDefaults[index];
            panelHTMLBuf.add('<br>
                <label>$label:
                <input id=tpp_assist_gamepad_${id}_format type=text value="$defaultValue" style="width: 5em;">
                </label>');
        }

        panelHTMLBuf.add("
            </details>
            </fieldset>

            <fieldset style='border: 1px solid gray; padding: 0.25em'>
            <legend>AutoSend</legend>
            <label for=tpp_assist_auto_send_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_auto_send_checkbox>
                Automatically Send on click
            </label>
            <label for=tpp_assist_avoid_ban_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_avoid_ban_checkbox checked=checked>
                Don't autosend if clicked too fast (helps avoid global ban)
            </label>
            </fieldset>
        ");

        settingsPanel.innerHTML = panelHTMLBuf.toString();

        Browser.document.body.appendChild(settingsPanel);

        var element = Browser.document.getElementById("tpp_assist_auto_send_checkbox");
        throwIfNull(element);
        autoSendCheckbox = cast(element, InputElement);
        autoSendCheckbox.onchange = (event:Event) -> {
            saveSettings();
        }

        element = Browser.document.getElementById("tpp_assist_avoid_ban_checkbox");
        throwIfNull(element);
        avoidBanCheckbox = cast(element, InputElement);

        element = Browser.document.querySelector("div.chat-input__buttons-container > div > div > button[data-a-target='chat-send-button']");

        throwIfNull(element);
        sendButton = cast(element, ButtonElement);

        setUpTouchscreenElements();
        setUpGamepadElements();
    }

    function setUpTouchscreenElements() {
        var enableCheckbox = cast(Browser.document.getElementById("tpp_assist_enable_checkbox"), InputElement);
        enableCheckbox.onclick = function (event:Event) {
            showTouchscreenOverlay(enableCheckbox.checked);
            loadSettings();
        }

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

    function setUpGamepadElements() {
        var gamepadEnableCheckbox = cast(Browser.document.getElementById("tpp_assist_gamepad_enable_checkbox"), InputElement);
        gamepadEnableCheckbox.onclick = function (event:Event) {
            if (gamepadEnableCheckbox.checked) {
                gamepadHandler.enable();
            } else {
                gamepadHandler.disable();
            }
        }

        for (id in gamepadButtonIds) {
            final element = cast(Browser.document.getElementById('tpp_assist_gamepad_${id}_format'), InputElement);
            gamepadButtonFormatInputs.push(element);
            element.onchange = (event:Event) -> {
                saveSettings();
            };
        }
    }

    function installTouchscreenOverlay() {
        touchScreenOverlay = Browser.document.createDivElement();
        touchScreenOverlay.classList.add("tpp-input-assist");
        touchScreenOverlay.style.border = "0.1em solid grey";
        touchScreenOverlay.style.zIndex = "3001";
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

        new JQuery(clickReceiver).click(function (event:js.jquery.Event) {
            var coord = calcCoordinate(event);
            var text = touchscreenFormat
                .replace("{x}", Std.string(coord.x))
                .replace("{y}", Std.string(coord.y));

            coordDisplay.textContent = '${coord.x},${coord.y} *';
            sendText(text);
        });

        new JQuery(clickReceiver).mousemove(function (event:js.jquery.Event) {
            var coord = calcCoordinate(event);
            coordDisplay.textContent = '${coord.x},${coord.y}';
        });

        new JQuery(clickReceiver).mouseleave(function (event:js.jquery.Event) {
            coordDisplay.textContent = "";
        });

        var jq = new JQuery(touchScreenOverlay);
        untyped jq.draggable({
            handle: dragHandle,
            containment: "document",
            stop: function () { saveSettings(); }
            })
            .resizable({
                stop: function (event: Event, ui: Dynamic) {
                    saveSettings();
            }
        });
    }

    function sendText(text:String) {
        // Bypass same message in 30 seconds filter
        if (text == lastSendText) {
            text = text.substr(0, 1).toUpperCase() + text.substr(1);
        }

        // Trigger React
        // https://github.com/facebook/react/issues/10135
        untyped Object.getOwnPropertyDescriptor(Object.getPrototypeOf(textarea), "value").set.call(textarea, text);
        var changeEvent = new Event("input", { bubbles: true, cancelable: true });
        textarea.dispatchEvent(changeEvent);

        if (autoSendCheckbox.checked) {
            var dateNow = Date.now();

            if (dateNow.getTime() - lastSendTime.getTime() < 1.5 * 1000 && avoidBanCheckbox.checked) {
                coordDisplay.textContent += " Slow down! Msg not sent";
                return;
            }

            lastSendTime = dateNow;
            lastSendText = text;

            new JQuery(sendButton).focus();
            new JQuery(textarea).focus();

            var clickEvent = new Event("click", { bubbles: true, cancelable: true });
            sendButton.dispatchEvent(clickEvent);
        }
    }

    function calcCoordinate(event:js.jquery.Event):XY {
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

            if (touchScreenOverlay.style.top == "") {
                touchScreenOverlay.style.top = top;
                touchScreenOverlay.style.left = left;
            }
        } else {
            touchScreenOverlay.style.display = "none";
        }
    }

    function gamepadInputCallback(buttons:Array<Bool>) {
        final parts = [];

        for (index in 0...25) {
            if (buttons[index]) {
                final value = gamepadButtonFormatInputs[index].value;
                parts.push(value);
            }
        }

        if (parts.length <= 3) {
            final text = parts.join("+");
            coordDisplay.textContent = text;
            sendText(text);
        }
    }

    function loadSettings() {
        var docString = Browser.window.localStorage.getItem(
            'tppinputassist-${Browser.window.location.pathname}-settings');
        if (docString == null) {
            return;
        }

        var doc:DynamicAccess<Any> = Json.parse(docString);

        if (doc.exists("width") && doc.exists("height") && doc.exists("format")) {
            widthInput.value = Std.string(touchscreenWidth = doc.get("width"));
            heightInput.value = Std.string(touchscreenHeight = doc.get("height"));
            formatElement.value = touchscreenFormat = doc.get("format");
        }

        if (doc.exists("overlayWidth") && doc.exists("overlayHeight")) {
            touchScreenOverlay.style.width = doc.get("overlayWidth");
            touchScreenOverlay.style.height = doc.get("overlayHeight");
        }

        if (doc.exists("overlayX") && doc.exists("overlayY")) {
            touchScreenOverlay.style.left = doc.get("overlayX");
            touchScreenOverlay.style.top = doc.get("overlayY");
        }

        if (doc.exists("autoSend")) {
            autoSendCheckbox.checked = doc.get("autoSend");
        }

        if (doc.exists("avoidBan")) {
            avoidBanCheckbox.checked = doc.get("avoidBan");
        }

        for (index in 0...gamepadButtonIds.length) {
            final id = gamepadButtonIds[index];

            if (doc.exists('gamepad-$id-format')) {
                gamepadButtonFormatInputs[index].value = doc.get('gamepad-$id-format');
            }
        }
    }

    function saveSettings() {
        var doc:DynamicAccess<Any> = {
            width: widthInput.value,
            height: heightInput.value,
            format: formatElement.value,
            overlayWidth: touchScreenOverlay.style.width,
            overlayHeight: touchScreenOverlay.style.height,
            overlayX: touchScreenOverlay.style.left,
            overlayY: touchScreenOverlay.style.top,
            autoSend: autoSendCheckbox.checked,
            avoidBan: avoidBanCheckbox.checked
        };

        for (index in 0...gamepadButtonIds.length) {
            final id = gamepadButtonIds[index];
            final value = gamepadButtonFormatInputs[index].value;
            doc.set('gamepad-$id-format', value);
        }

        Browser.window.localStorage.setItem(
            'tppinputassist-${Browser.window.location.pathname}-settings',
            Json.stringify(doc)
        );
    }
}

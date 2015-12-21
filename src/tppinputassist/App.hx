package tppinputassist;

import js.JQuery;
import js.html.InputElement;
import js.html.Event;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.Element;
import js.html.TextAreaElement;
import js.Browser;


typedef XY = {
    x:Int, y:Int
};


class ElementNotFoundError {
    public function new() {
    }
}


class App {
    var textarea:TextAreaElement;
    var touchScreenOverlay:DivElement;
    var settingsPanel:DivElement;
    var touchscreenWidth = 320;
    var touchscreenHeight = 240;

    public function new() {
    }

    public function run() {
        new JQuery(Browser.document.body).ready(function(event:JqEvent) {
            trace("Page loaded, trying install script");
            jamJQueryIn();
        });
    }

    function jamJQueryIn() {
        untyped JQuery.getScript("https://code.jquery.com/ui/1.11.4/jquery-ui.min.js",
            function() {
                installSettingsButton();
            }
        );

        var div = cast(Browser.document.createElement("div"), DivElement);
        div.innerHTML = "
            <link rel='stylesheet' href='https://code.jquery.com/ui/1.11.4/themes/dark-hive/jquery-ui.css' type='text/css'>
        ";
        Browser.document.body.appendChild(div);
    }

    function installSettingsButton() {
        var buttonContainer:Element = Browser.document.querySelector(".chat-buttons-container");

        throwIfNull(buttonContainer);

        var enableElement:AnchorElement = cast(Browser.document.createElement("a"), AnchorElement);
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

        element = Browser.document.querySelector(".chat_text_input");
        throwIfNull(element);
        textarea = cast(element, TextAreaElement);

        installSettingsPanel();
        installTouchscreenOverlay();
    }

    function throwIfNull(element:Element) {
        if (element == null) {
            throw new ElementNotFoundError();
        }
    }

    function installSettingsPanel() {
        settingsPanel = cast(Browser.document.createElement("div"), DivElement);
        settingsPanel.style.display = "none";

        // The label has inline styles to override the Twitch CSS
        settingsPanel.innerHTML = "
            <fieldset>
            <legend>Touchscreen</legend>
            <label for=tpp_assist_enable_checkbox
                style='margin: inherit; color: inherit; display: inline-block'
            >
                <input type=checkbox id=tpp_assist_enable_checkbox>
                Enable tap overlay
            </label>
            <br>
            Width: <input id=tpp_assist_width_input type=number min=0 value=320 style='width: 5em;'>
            <br>
            Height: <input id=tpp_assist_height_input type=number min=0 value=240 style='width: 5em;'>
            </fieldset>
        ";

        Browser.document.body.appendChild(settingsPanel);

        var enableCheckbox = cast(Browser.document.getElementById("tpp_assist_enable_checkbox"), InputElement);
        enableCheckbox.onclick = function (event:Event) {
            showTouchscreenOverlay(enableCheckbox.checked);
        }

        var widthInput = cast(Browser.document.getElementById("tpp_assist_width_input"), InputElement);
        var heightInput = cast(Browser.document.getElementById("tpp_assist_width_input"), InputElement);

        widthInput.onchange = heightInput.onchange = function(event:Event) {
            touchscreenWidth = Std.parseInt(widthInput.value);
            touchscreenHeight = Std.parseInt(heightInput.value);
        }
    }

    function installTouchscreenOverlay() {
        touchScreenOverlay = cast(Browser.document.createElement("div"), DivElement);
        touchScreenOverlay.style.border = "0.1em solid grey";
        touchScreenOverlay.style.zIndex = "99";
        touchScreenOverlay.style.width = "100px";
        touchScreenOverlay.style.height = "100px";
        touchScreenOverlay.style.display = "none";
        touchScreenOverlay.style.position = "absolute";

        var dragHandle = cast(Browser.document.createElement("div"), DivElement);
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

        var clickReceiver = cast(Browser.document.createElement("div"), DivElement);
        touchScreenOverlay.appendChild(clickReceiver);
        clickReceiver.style.width = "100%";
        clickReceiver.style.height = "100%";

        Browser.document.body.appendChild(touchScreenOverlay);

        new JQuery(clickReceiver).click(function (event:JqEvent) {
            var coord = calcCoordinate(event);
            new JQuery(textarea).focus().val('${coord.x},${coord.y}');
        });

        new JQuery(clickReceiver).mousemove(function (event:JqEvent) {
            var coord = calcCoordinate(event);
            dragHandle.innerText = '${coord.x},${coord.y}';
        });

        new JQuery(clickReceiver).mouseleave(function (event:JqEvent) {
            dragHandle.innerText = "";
        });

        var jq = new JQuery(touchScreenOverlay);
        untyped jq.draggable({"handle": dragHandle}).resizable();
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
}

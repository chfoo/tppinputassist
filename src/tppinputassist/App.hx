package tppinputassist;

import haxe.DynamicAccess;
import haxe.Json;
import js.Browser;
import js.html.ButtonElement;
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Element;
import js.html.Event;
import js.html.InputElement;
import js.html.InputEvent;
import js.html.MutationObserver;
import js.html.SelectElement;
import js.html.StyleElement;
import js.jquery.JQuery;

using StringTools;


typedef XY = {
    x:Int, y:Int
};


class ElementNotFoundError {
    public function new() {
    }
}


enum ClickMode {
    Touch;
    Draw;
}

class App {
    var running = false;
    var installAttemptCount = 0;
    var textarea:DivElement;
    var jqueryStyleElement: StyleElement;
    var settingsButtonContainer:DivElement;
    var touchScreenOverlay:DivElement;
    var clickReceiver:CanvasElement;
    var settingsPanel:DivElement;
    var enableCheckbox:InputElement;
    var quickOverlayToggleCheckbox:InputElement;
    var autoSendCheckbox:InputElement;
    var avoidBanCheckbox:InputElement;
    var sendButton:ButtonElement;
    var coordDisplay:DivElement;
    var widthInput:InputElement;
    var heightInput:InputElement;
    var formatElement:InputElement;
    var dragFormatElement:InputElement;
    var pointFormatElement:InputElement;
    var linePointJoinElement:InputElement;
    var curvePointJoinElement:InputElement;
    var curveTypeElement:SelectElement;
    var quickOverlayToggleElement:DivElement;
    var quickOverlayToggleButton:ButtonElement;
    var drawingToolbarContainer:DivElement;
    var touchscreenWidth = 320;
    var touchscreenHeight = 240;
    var touchscreenFormat = "{x},{y}";
    var touchscreenDragFormat = "{x1},{y1}>{x2},{y2}";
    var pointFormat = "{x},{y}";
    var linePointJoin = ">";
    var curvePointJoin = "~";
    var curveType:String = "BezierVariableDegree";
    var lastSendTime:Date;
    var lastSendText = "";
    var clickMode:ClickMode = ClickMode.Touch;
    var clickState:ClickState;
    var drawingToolbarButtonTimerId:Int = 0;
    var errorReportCount:Int = 0;
    var elementConnectedTimerId:Int = 0;
    final gamepadButtonFormatInputs:Array<InputElement>;
    final gamepadHandler:GamepadHandler;
    final drawingTool:DrawingTool;

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
        clickState = new ClickState();
        gamepadButtonFormatInputs = [];
        gamepadHandler = new GamepadHandler();
        drawingTool = new DrawingTool();
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

            Browser.window.setTimeout(installInit, 2000);
        });
    }

    function installInit() {
        if (!detectButtonContainer() && installAttemptCount < 10) {
            trace("Button container not found, retrying.");
            installAttemptCount += 1;
            Browser.window.setTimeout(installInit, 5000);
            return;
        } else if (!detectButtonContainer()) {
            trace("Button container not found, exiting.");
            return;
        }

        installAttemptCount = 0;

        trace("Installing CSS");
        installJQueryCSS();

        trace("Installing settings button");
        installSettingsButton();
    }

    function installJQueryCSS() {
        jqueryStyleElement = Browser.document.createStyleElement();
        jqueryStyleElement.textContent = CSS.getCSS();
        Browser.document.body.appendChild(jqueryStyleElement);
    }

    function installSettingsButton() {
        var buttonContainer:Element;

        buttonContainer = querySelector(".chat-input__buttons-container > div:nth-child(2)");

        settingsButtonContainer = Browser.document.createDivElement();
        settingsButtonContainer.id = "tppinputassistSettingsButtonContainer";

        var enableElement = Browser.document.createAnchorElement();
        enableElement.textContent = "TPP Input Assist";
        enableElement.href = "#";
        enableElement.onclick = function (event:Dynamic) {
            if (settingsPanel == null) {
                try {
                    installComponents();
                } catch (error:Any) {
                    reportError('JS error:\n\n$error');
                    throw error;
                }
            }

            var jq = new JQuery(settingsPanel);
            untyped jq.dialog({"title": "TPP Input Assist Settings", "width": 400, "height": 300});
            untyped jq.dialog("widget").css("z-index", "3002");
            return false;
        }
        enableElement.style.fontSize = "80%";

        settingsButtonContainer.appendChild(enableElement);
        buttonContainer.insertBefore(settingsButtonContainer, buttonContainer.firstElementChild);

        runCheckSettingsButtonTimer();
    }

    function runCheckSettingsButtonTimer() {
        if (elementConnectedTimerId == 0) {
            elementConnectedTimerId = Browser.window.setTimeout(() -> {
                Browser.window.requestAnimationFrame(checkSettingsButton);
            }, 5000);
        }
    }

    // The chat panel reloads several times, rendering the panel as new,
    // when the page is first opened. (I wouldn't be surprised that the bug is
    // caused by someone's AI vibe coding.)
    // Ideally, mutation observer should be used. But we can't observe removal
    // of the element itself without observing the root and all children.
    function checkSettingsButton(_time:Float) {
        elementConnectedTimerId = 0;

        if (!settingsButtonContainer.isConnected) {
            reinstall();
        } else {
            runCheckSettingsButtonTimer();
        }
    }

    function installComponents() {
        var element:Element;

        element = querySelector("div[data-a-target='chat-input']");
        textarea = cast(element, DivElement);

        installSettingsPanel();
        installTouchscreenOverlay();
        installQuickToggleOverlay();

        setUpClickStateReactor();
        setUpTouchscreenElements();
        setUpQuickOverlayToggleElements();
        setUpGamepadElements();

        loadSettings();

        gamepadHandler.onInput = gamepadInputCallback;
    }

    function reinstall() {
        trace("Reinstalling..");
        uninstallAll();
        Browser.window.setTimeout(installInit, 1000);
    }

    function uninstallAll() {
        if (jqueryStyleElement != null) {
            jqueryStyleElement.remove();
            jqueryStyleElement = null;
        }
        if (settingsButtonContainer != null) {
            settingsButtonContainer.remove();
            settingsButtonContainer = null;
        }
        if (settingsPanel != null) {
            var jq = new JQuery(settingsPanel);
            untyped jq.dialog("destroy");
            settingsPanel.remove();
            settingsPanel = null;
        }
        if (touchScreenOverlay != null) {
            touchScreenOverlay.remove();
            touchScreenOverlay = null;
        }
        if (quickOverlayToggleElement != null) {
            quickOverlayToggleElement.remove();
            quickOverlayToggleElement = null;
        }
    }

    function querySelector(query:String):Element {
        var element = Browser.document.querySelector(query);

        if (element == null) {
            reportError('querySelector failed: $query');
            throw new ElementNotFoundError();
        }

        return element;
    }

    function getElementById(id:String):Element {
        var element = Browser.document.getElementById(id);

        if (element == null) {
            reportError('getElementById failed: $id');
            throw new ElementNotFoundError();
        }

        return element;
    }

    function reportError(message:String) {
        Browser.console.error('tppinputassist: $message');

        if (errorReportCount == 0) {
            var window = Browser.window.open("", "tppinputassist-error", "");
            var element = Browser.document.createPreElement();
            element.textContent = 'TPP Input Assist error:\n\n$message';
            window.document.body.appendChild(element);
        }

        errorReportCount += 1;
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
            <label for=tpp_assist_quick_overlay_toggle_checkbox
                style='margin: inherit; color: inherit; display: inline-block;'
            >
                <input type=checkbox id=tpp_assist_quick_overlay_toggle_checkbox>
                Show quick overlay toggle button
            </label>

            <br>
            <label>Width: <input id=tpp_assist_width_input type=number min=0 value=320 style='width: 5em;'></label>
            <br>
            <label>Height: <input id=tpp_assist_height_input type=number min=0 value=240 style='width: 5em;'></label>
            <br>
            <label>Format: <input id=tpp_assist_format_input type=text value='{x},{y}' style='width: 5em;'></label>
            <br>
            <label>Drag: <input id=tpp_assist_drag_format_input type=text value='{x1},{y1}>{x2},{y2}' style='width: 10em;'></label>
            <br>
            <br>
            <details>
                <summary>Drawing mode</summary>
                <label>Point format: <input id=tpp_assist_point_format type=text value='{x},{y}' style='width: 5em;'></label>
                <br>
                <label>Line point separator: <input id=tpp_assist_line_join_format type=text value='>' style='width: 5em;'></label>
                <br>
                <label>Curve point separator: <input id=tpp_assist_curve_join_format type=text value='~' style='width: 5em;'></label>
                <br>
                <label>Curve type:
                    <select id=tpp_assist_curve_type>
                        <option value=BezierVariableDegree>Bézier curve of variable degree</option>
                    </select>
                </label>
            </details>
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
            <fieldset style='border: 1px solid gray; padding: 0.25em'>
            <legend>Troubleshoot</legend>
                <button id=tpp_assist_reset_positions_button style='border:1px solid grey;color:#eee;background:#333'>Reset draggable box positions</button>
            </fieldset>
        ");

        settingsPanel.innerHTML = panelHTMLBuf.toString();

        Browser.document.body.appendChild(settingsPanel);

        var element = getElementById("tpp_assist_auto_send_checkbox");
        autoSendCheckbox = cast(element, InputElement);
        autoSendCheckbox.onchange = (event:Event) -> {
            saveSettings();
        }

        element = getElementById("tpp_assist_avoid_ban_checkbox");
        avoidBanCheckbox = cast(element, InputElement);

        element = querySelector("div.chat-input__buttons-container button[data-a-target='chat-send-button']");

        sendButton = cast(element, ButtonElement);

        var resetButton = cast(getElementById("tpp_assist_reset_positions_button"), ButtonElement);
        resetButton.onclick = (event) -> {
            touchScreenOverlay.style.left = "100px";
            touchScreenOverlay.style.top = "100px";
            quickOverlayToggleElement.style.left = "";
            quickOverlayToggleElement.style.right = "0em";
            quickOverlayToggleElement.style.top = "0em";
            drawingToolbarContainer.style.left = "";
            drawingToolbarContainer.style.right = "-6em";
            drawingToolbarContainer.style.top = "0px";
        };
    }

    function setUpTouchscreenElements() {
        enableCheckbox = cast(getElementById("tpp_assist_enable_checkbox"), InputElement);
        enableCheckbox.onclick = function (event:Event) {
            showTouchscreenOverlay(enableCheckbox.checked);
            loadSettings();
        }

        quickOverlayToggleCheckbox = cast(getElementById("tpp_assist_quick_overlay_toggle_checkbox"), InputElement);
        quickOverlayToggleCheckbox.onclick = function (event:Event) {
            if (quickOverlayToggleCheckbox.checked) {
                quickOverlayToggleElement.style.display = "inline-block";
            } else {
                quickOverlayToggleElement.style.display = "none";
            }
            saveSettings();
        }

        widthInput = cast(getElementById("tpp_assist_width_input"), InputElement);
        heightInput = cast(getElementById("tpp_assist_height_input"), InputElement);

        widthInput.onchange = heightInput.onchange = function(event:Event) {
            clickReceiver.width = touchscreenWidth = Std.parseInt(widthInput.value);
            clickReceiver.height = touchscreenHeight = Std.parseInt(heightInput.value);
            saveSettings();
        }

        formatElement = cast(getElementById("tpp_assist_format_input"), InputElement);
        formatElement.onchange = function(event:Event) {
            touchscreenFormat = formatElement.value;
            saveSettings();
        }

        dragFormatElement = cast(getElementById("tpp_assist_drag_format_input"), InputElement);
        dragFormatElement.onchange = function(event:Event) {
            touchscreenDragFormat = dragFormatElement.value;
            saveSettings();
        }

        pointFormatElement = cast(getElementById("tpp_assist_point_format"), InputElement);
        pointFormatElement.onchange = function(event:Event) {
            pointFormat = pointFormatElement.value;
            saveSettings();
        }

        linePointJoinElement = cast(getElementById("tpp_assist_line_join_format"), InputElement);
        linePointJoinElement.onchange = function(event:Event) {
            linePointJoin = linePointJoinElement.value;
            saveSettings();
        }

        curvePointJoinElement = cast(getElementById("tpp_assist_curve_join_format"), InputElement);
        curvePointJoinElement.onchange = function(event:Event) {
            curvePointJoin = curvePointJoinElement.value;
            saveSettings();
        }

        curveTypeElement = cast(getElementById("tpp_assist_curve_type"), SelectElement);
        curveTypeElement.onchange = function(event:Event) {
            curveType = curveTypeElement.value;
            saveSettings();
        }
    }

    function setUpQuickOverlayToggleElements() {
        quickOverlayToggleButton.onclick = () -> enableCheckbox.click();
    }

    function setUpGamepadElements() {
        var gamepadEnableCheckbox = cast(getElementById("tpp_assist_gamepad_enable_checkbox"), InputElement);
        gamepadEnableCheckbox.onclick = function (event:Event) {
            if (gamepadEnableCheckbox.checked) {
                gamepadHandler.enable();
            } else {
                gamepadHandler.disable();
            }
        }

        for (id in gamepadButtonIds) {
            final element = cast(getElementById('tpp_assist_gamepad_${id}_format'), InputElement);
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
        coordDisplay.style.opacity = "0.8";
        coordDisplay.style.color = "white";
        coordDisplay.style.fontSize = "0.75em";
        coordDisplay.style.width = "100%";
        coordDisplay.textContent = "Drag & Size Me";
        coordDisplay.style.textShadow = "0px 0px 4px black";

        clickReceiver = Browser.document.createCanvasElement();
        touchScreenOverlay.appendChild(clickReceiver);
        clickReceiver.style.position = "absolute";
        clickReceiver.style.top = "0px";
        clickReceiver.style.width = "100%";
        clickReceiver.style.height = "100%";
        clickReceiver.style.cursor = "crosshair";
        clickReceiver.style.userSelect = "none";
        clickReceiver.style.imageRendering = "pixelated";
        clickReceiver.width = touchscreenWidth;
        clickReceiver.height = touchscreenHeight;

        drawingTool.setElements(touchScreenOverlay, clickReceiver);

        var dragHandle = Browser.document.createDivElement();
        touchScreenOverlay.appendChild(dragHandle);
        dragHandle.style.border = "0.1em outset grey";
        dragHandle.style.position = "relative";
        dragHandle.style.top = "-1.2em";
        dragHandle.style.left = "0em";
        dragHandle.style.background = "grey";
        dragHandle.style.height = "1em";
        dragHandle.style.cursor = "move";
        dragHandle.style.opacity = "0.5";
        dragHandle.style.color = "white";

        drawingToolbarContainer = Browser.document.createDivElement();
        touchScreenOverlay.appendChild(drawingToolbarContainer);
        drawingToolbarContainer.style.display = "none";
        drawingToolbarContainer.style.position = "absolute";
        drawingToolbarContainer.style.right = "-6em";
        drawingToolbarContainer.style.top = "0px";
        drawingToolbarContainer.style.width = "6em";
        drawingToolbarContainer.style.opacity = "0.9";

        var drawingToolDragHandle = Browser.document.createDivElement();
        drawingToolbarContainer.appendChild(drawingToolDragHandle);
        drawingToolDragHandle.style.border = "0.1em outset grey";
        drawingToolDragHandle.style.position = "relative";
        drawingToolDragHandle.style.left = "0em";
        drawingToolDragHandle.style.background = "grey";
        drawingToolDragHandle.style.height = "0.75em";
        drawingToolDragHandle.style.width = "4em";
        drawingToolDragHandle.style.cursor = "move";
        drawingToolDragHandle.style.opacity = "0.5";
        drawingToolDragHandle.style.color = "white";

        drawingToolbarContainer.appendChild(drawingTool.toolbarElement);
        drawingToolbarContainer.appendChild(Browser.document.createBRElement());
        drawingToolbarContainer.appendChild(Browser.document.createBRElement());
        drawingToolbarContainer.appendChild(drawingTool.actionBarElement);

        function resetDrawingToolbarContainerTimer() {
            if (drawingToolbarButtonTimerId != 0) {
                Browser.window.clearTimeout(drawingToolbarButtonTimerId);
                drawingToolbarButtonTimerId = 0;
            }

            drawingToolbarContainer.style.display = "block";

            drawingToolbarButtonTimerId = Browser.window.setTimeout((event) -> {
                drawingToolbarContainer.style.display = "none";
            }, 10000);
        }

        Browser.document.body.appendChild(touchScreenOverlay);

        final jqClickReceiver = new JQuery(clickReceiver);

        jqClickReceiver.mousedown((event:js.jquery.Event) -> {
            final coord = calcCoordinate(event);
            clickState.setMouseDownCoordinates(coord.x, coord.y);
            if (clickMode == ClickMode.Draw) {
                drawingTool.addDrawHandle(coord.x, coord.y);
            }
        });

        jqClickReceiver.mouseup((event:js.jquery.Event) -> {
            final coord = calcCoordinate(event);
            clickState.setMouseUpCoordinates(coord.x, coord.y);
        });

        jqClickReceiver.mousemove(function (event:js.jquery.Event) {
            var coord = calcCoordinate(event);
            clickState.setMouseMoveCoordinates(coord.x, coord.y);

            resetDrawingToolbarContainerTimer();
        });

        jqClickReceiver.mouseleave(function (event:js.jquery.Event) {
            clickState.setMouseLeave();
        });

        var jq = new JQuery(touchScreenOverlay);
        untyped jq.draggable({
            handle: dragHandle,
            containment: "document",
            stop: function () { saveSettings(); },
            drag:
                (event, ui) -> {
                    ui.position.top = Math.max(10, ui.position.top);
                }
            })
            .resizable({
                stop: function (event: Event, ui: Dynamic) {
                    saveSettings();
            }
        });

        var jq = new JQuery(drawingToolbarContainer);
        untyped jq.draggable({
            handle: drawingToolDragHandle,
            containment: "document",
            stop: function () { saveSettings(); },
            drag:
                (event, ui) -> {
                    resetDrawingToolbarContainerTimer();
                }
        });
    }

    function installQuickToggleOverlay() {
        quickOverlayToggleElement = Browser.document.createDivElement();
        quickOverlayToggleElement.classList.add("tpp-input-assist");
        quickOverlayToggleElement.style.border = "0.1em solid grey";
        quickOverlayToggleElement.style.zIndex = "3001";
        quickOverlayToggleElement.style.display = "none";
        quickOverlayToggleElement.style.position = "absolute";
        quickOverlayToggleElement.style.right = "0em";
        quickOverlayToggleElement.style.top = "0em";
        quickOverlayToggleElement.style.width = "5em";

        final handle = Browser.document.createDivElement();
        handle.style.border = "0.1em outset grey";
        handle.style.background = "grey";
        handle.style.height = "1em";
        handle.style.width = "1em";
        handle.style.cursor = "move";
        handle.style.opacity = "0.5";
        handle.style.color = "white";
        handle.style.display = "inline-block";
        quickOverlayToggleElement.appendChild(handle);

        quickOverlayToggleButton = Browser.document.createButtonElement();
        quickOverlayToggleElement.appendChild(quickOverlayToggleButton);
        quickOverlayToggleButton.textContent = '📺👆';

        var jq = new JQuery(quickOverlayToggleElement);
        untyped jq.draggable({
            handle: handle,
            containment: "document",
            stop: () -> saveSettings()
        });

        Browser.document.body.appendChild(quickOverlayToggleElement);
    }

    function setUpClickStateReactor() {
        drawingTool.toolbarButtonSelected = () -> {
            if (drawingTool.selectedTool == DrawingTool.DrawingButton.Touch) {
                clickMode = Touch;
                clickReceiver.style.cursor = "crosshair";
                drawingTool.actionBarElement.style.display = "none";
            } else {
                clickMode = Draw;
                clickReceiver.style.cursor = "default";
                drawingTool.actionBarElement.style.display = "block";
            }
        }
        drawingTool.actionBarElement.style.display = "none";

        drawingTool.actionButtonSelected = (button) -> {
            switch button {
                case Clear:
                    drawingTool.clearDrawingHandlesAndCanvas();
                case Send:
                    var text = makeDrawingToolCommand();
                    sendText(text);
            }
        }

        drawingTool.changed = () -> {
            var text = makeDrawingToolCommand();
            prefillText(text);
        }

        clickState.eventCallback = (event) -> {
            switch clickMode {
                case Touch:
                    clickStateEventHandler(event);
                case Draw:
                    switch event {
                        case Hover(x, y):
                            coordDisplay.textContent = '${x},${y}';
                        default:
                            //pass
                    }
            }
        };
    }

    function clickStateEventHandler(event:ClickState.ClickEvent) {
        switch event {
            case Hover(x, y):
                coordDisplay.textContent = '${x},${y}';
                drawingTool.clearCanvas();
            case PointCommit(x, y):
                final text = touchscreenFormat
                    .replace("{x}", Std.string(x))
                    .replace("{y}", Std.string(y));

                coordDisplay.textContent = '${x},${y} *';
                sendText(text);
                drawingTool.clearCanvas();
            case HoverDrag(x1, y1, x2, y2):
                coordDisplay.textContent = '${x1},${y1}→${x2},${y2}';
                drawingTool.clearCanvas();
                drawingTool.drawLine(x1, y1, x2, y2);
            case DragCommit(x1, y1, x2, y2):
                final text = touchscreenDragFormat
                    .replace("{x1}", Std.string(x1))
                    .replace("{y1}", Std.string(y1))
                    .replace("{x2}", Std.string(x2))
                    .replace("{y2}", Std.string(y2));

                coordDisplay.textContent = '${x1},${y1}→${x2},${y2} *';
                sendText(text);
                drawingTool.clearCanvas();
            case Canceled:
                drawingTool.clearCanvas();
        }
    }

    function makeDrawingToolCommand():String {
        switch drawingTool.selectedTool {
            case Touch:
                throw "invalid state";
            case Line:
                return drawingTool.pointsToString(true, pointFormat, linePointJoin);
            case Curve:
                return drawingTool.pointsToString(false, pointFormat, curvePointJoin);
            case Freehand:
                // TODO
                throw "todo";
        }
    }

    function prefillText(text:String) {
        sendTextReal(text, false);
    }

    function sendText(text:String) {
        sendTextReal(text, true);
    }

    function sendTextReal(text:String, allowAutoSend:Bool) {
        // Bypass same message in 30 seconds filter
        if (text == lastSendText) {
            text = text.substr(0, 1).toUpperCase() + text.substr(1);
        }

        // Trigger Slate
        // https://github.com/facebook/react/issues/10135
        // https://stackoverflow.com/a/61360140/1524507
        // https://w3c.github.io/uievents/#dom-inputevent-inputevent
        // https://www.w3.org/TR/input-events-1/#interface-InputEvent
        // https://w3c.github.io/selection-api/
        var deleteEvent1 = new InputEvent("beforeinput", untyped { inputType: "deleteHardLineBackward", data: "" });
        var deleteEvent2 = new InputEvent("beforeinput", untyped { inputType: "deleteHardLineForward", data: "" });
        var changeEvent = new InputEvent("beforeinput", untyped { inputType: "insertText", data: text });
        textarea.focus();
        textarea.dispatchEvent(deleteEvent1);
        textarea.dispatchEvent(deleteEvent2);
        textarea.dispatchEvent(changeEvent);
        Browser.window.setTimeout(function () {
            textarea.blur();
        }, 50);

        if (autoSendCheckbox.checked && allowAutoSend) {
            var dateNow = Date.now();

            if (dateNow.getTime() - lastSendTime.getTime() < 1.5 * 1000 && avoidBanCheckbox.checked) {
                coordDisplay.textContent += " Slow down! Msg not sent";
                return;
            }

            lastSendTime = dateNow;
            lastSendText = text;

            Browser.window.setTimeout(function () {
                textarea.focus();
                sendButton.click();
            }, 100);
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
            widthInput.value = Std.string(clickReceiver.width = touchscreenWidth = doc.get("width"));
            heightInput.value = Std.string(clickReceiver.height = touchscreenHeight = doc.get("height"));
            formatElement.value = touchscreenFormat = doc.get("format");
        }

        if (doc.exists("dragFormat")) {
            dragFormatElement.value = touchscreenDragFormat = doc.get("dragFormat");
        }

        if (doc.get("overlayWidth") != "" && doc.get("overlayHeight") != "") {
            touchScreenOverlay.style.width = doc.get("overlayWidth");
            touchScreenOverlay.style.height = doc.get("overlayHeight");
        }

        if (doc.get("overlayX") != "" && doc.get("overlayY") != "") {
            touchScreenOverlay.style.left = doc.get("overlayX");
            touchScreenOverlay.style.top = doc.get("overlayY");
        }

        if (doc.exists("showQuickOverlayToggle")) {
            quickOverlayToggleCheckbox.checked = doc.get("showQuickOverlayToggle");

            if (quickOverlayToggleCheckbox.checked) {
                quickOverlayToggleElement.style.display = "inline-block";
            }
        }

        if (doc.exists("showQuickOverlayToggleX") && doc.exists("showQuickOverlayToggleY")) {
            quickOverlayToggleElement.style.left = doc.get("showQuickOverlayToggleX");
            quickOverlayToggleElement.style.top = doc.get("showQuickOverlayToggleY");
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

        if (doc.exists("pointFormat")) {
            pointFormatElement.value = pointFormat = doc.get("pointFormat");
            linePointJoinElement.value = linePointJoin = doc.get("linePointJoin");
            curvePointJoinElement.value = curvePointJoin = doc.get("curvePointJoin");
        }

        if (doc.exists("curveType")) {
            curveTypeElement.value = curveType = doc.get("curveType");
        }

        if (doc.exists("drawingToolbarContainerX")) {
            drawingToolbarContainer.style.left = doc.get("drawingToolbarContainerX");
            drawingToolbarContainer.style.top = doc.get("drawingToolbarContainerY");
        }
    }

    function saveSettings() {
        var doc:DynamicAccess<Any> = {
            width: widthInput.value,
            height: heightInput.value,
            format: formatElement.value,
            dragFormat: dragFormatElement.value,
            pointFormat: pointFormatElement.value,
            linePointJoin: linePointJoinElement.value,
            curvePointJoin: curvePointJoinElement.value,
            curveType: curveTypeElement.value,
            overlayWidth: touchScreenOverlay.style.width,
            overlayHeight: touchScreenOverlay.style.height,
            overlayX: touchScreenOverlay.style.left,
            overlayY: touchScreenOverlay.style.top,
            showQuickOverlayToggle: quickOverlayToggleCheckbox.checked,
            showQuickOverlayToggleX: quickOverlayToggleElement.style.left,
            showQuickOverlayToggleY: quickOverlayToggleElement.style.top,
            autoSend: autoSendCheckbox.checked,
            avoidBan: avoidBanCheckbox.checked,
            drawingToolbarContainerX: drawingToolbarContainer.style.left,
            drawingToolbarContainerY: drawingToolbarContainer.style.top,
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

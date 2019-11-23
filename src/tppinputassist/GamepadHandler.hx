package tppinputassist;

import js.html.GamepadMappingType;
import js.html.GamepadEvent;
import js.html.Gamepad;
import js.Browser;

class GamepadHandler {
    static inline final STICK_PRESS_THRESHOLD = 0.2;
    static inline final CHORD_TIME_THRESHOLD = 200.0; // milliseconds
    final gamepadIndexes:Array<Int>;
    final pressStates:Array<GamepadPressState>;
    var pollTimerId:Null<Int>;
    final logicalButtonsPressed:Array<Bool>;

    public function new() {
        gamepadIndexes = [];
        pressStates = [];
        logicalButtonsPressed = [];

        attachListeners();
    }

    function attachListeners() {
        Browser.window.addEventListener("gamepadconnected", gamepadConnectedCallback);
        Browser.window.addEventListener("gamepaddisconnected", gamepadDisconnectedCallback);
    }

    function gamepadConnectedCallback(event:GamepadEvent) {
        final gamepad = event.gamepad;

        gamepadIndexes.push(gamepad.index);
        pressStates.push(new GamepadPressState());

        if (gamepad.mapping != GamepadMappingType.STANDARD) {
            trace('${gamepad.id} is not using standard mapping! It may not work correctly');
        }
    }

    function gamepadDisconnectedCallback(event:GamepadEvent) {
        final gamepad = event.gamepad;

        final arrayIndex = gamepadIndexes.indexOf(gamepad.index);
        pressStates.splice(arrayIndex, 1);
        gamepadIndexes.remove(gamepad.index);
    }

    public function enable() {
        if (pollTimerId == null) {
            pollTimerId = Browser.window.requestAnimationFrame(frameCallback);
        }
    }

    public function disable() {
        if (pollTimerId != null) {
            Browser.window.cancelAnimationFrame(pollTimerId);
            pollTimerId = null;
        }
    }

    dynamic public function onInput(buttons:Array<Bool>) {

    }

    function frameCallback(timestamp:Float) {
        final gamepads = Browser.navigator.getGamepads();

        for (index in 0...gamepadIndexes.length) {
            final gamepadIndex = gamepadIndexes[index];
            processButtons(gamepads[gamepadIndex], pressStates[index]);
        }

        pollTimerId = Browser.window.requestAnimationFrame(frameCallback);
    }

    function processButtons(gamepad:Gamepad, state:GamepadPressState) {
        var numPressed = 0;

        for (index in 0...16) {
            if (gamepad.buttons[index].pressed) {
                state.pressTimestamps[index] = gamepad.timestamp;
                numPressed += 1;
            } else if (state.pressTimestamps[index] != 0 && state.releaseTimestamps[index] == 0) {
                state.releaseTimestamps[index] = gamepad.timestamp;
            }
        }

        for (index in 0...4) {
            var stateIndexLower;
            var stateIndexUpper;

            switch index {
                case 0:
                    stateIndexLower = LogicalButton.LeftStickLeft;
                    stateIndexUpper = LogicalButton.LeftStickRight;
                case 1:
                    stateIndexLower = LogicalButton.LeftStickUp;
                    stateIndexUpper = LogicalButton.LeftStickDown;
                case 2:
                    stateIndexLower = LogicalButton.RightStickLeft;
                    stateIndexUpper = LogicalButton.RightStickRight;
                case 3:
                    stateIndexLower = LogicalButton.RightStickUp;
                    stateIndexUpper = LogicalButton.RightStickDown;
                default:
                    throw "shouldn't reach here";
            }

            if (gamepad.axes[index] <= -STICK_PRESS_THRESHOLD) {
                state.pressTimestamps[stateIndexLower] = gamepad.timestamp;
                numPressed += 1;
            } else if (gamepad.axes[index] >= STICK_PRESS_THRESHOLD) {
                state.pressTimestamps[stateIndexUpper] = gamepad.timestamp;
                numPressed += 1;
            } else if (state.pressTimestamps[stateIndexLower] != 0 && state.releaseTimestamps[stateIndexLower] == 0) {
                state.releaseTimestamps[stateIndexLower] = gamepad.timestamp;
            } else if (state.pressTimestamps[stateIndexUpper] != 0 && state.releaseTimestamps[stateIndexUpper] == 0) {
                state.releaseTimestamps[stateIndexUpper] = gamepad.timestamp;
            }
        }

        if (numPressed > 0) {
            state.previouslyPressed = true;
        }

        if (numPressed == 0 && state.previouslyPressed) {
            final thresholdTimestamp = gamepad.timestamp - CHORD_TIME_THRESHOLD;

            for (index in 0...26) {
                logicalButtonsPressed[index] = state.releaseTimestamps[index] >= thresholdTimestamp;
            }

            onInput(logicalButtonsPressed);
            state.reset();
        }
    }
}

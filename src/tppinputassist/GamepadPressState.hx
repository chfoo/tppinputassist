package tppinputassist;

class GamepadPressState {
    public final pressTimestamps:Array<Float>;
    public final releaseTimestamps:Array<Float>;
    public var numPressed:Int = 0;
    public var previouslyPressed:Bool = false;

    public function new() {
        pressTimestamps = [for (i in 0...26) 0];
        releaseTimestamps = [for (i in 0...26) 0];
    }

    public function reset() {
        for (index in 0...pressTimestamps.length) {
            pressTimestamps[index] = 0;
            releaseTimestamps[index] = 0;
        }

        numPressed = 0;
        previouslyPressed = false;
    }
}

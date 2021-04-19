package tppinputassist;

enum ClickEvent {
    Hover(x:Float, y:Float);
    PointCommit(x:Float, y:Float);
    HoverDrag(x1:Float, y1:Float, x2:Float, y2:Float);
    DragCommit(x1:Float, y1:Float, x2:Float, y2:Float);
    Canceled;
}

class ClickState {
    final dragThreshold = 8;

    // Coordinates in touchscreen coordinates (not page coordinates)
    var mousePressed:Bool = false;
    var startX:Float = 0.0;
    var startY:Float = 0.0;

    public function new() {

    }

    dynamic public function eventCallback(event:ClickEvent) {}

    public function setMouseDownCoordinates(x:Float, y:Float) {
        startX = x;
        startY = y;
        mousePressed = true;
    }

    public function setMouseMoveCoordinates(x:Float, y:Float) {
        if (mousePressed) {
            final distance = Math.sqrt(Math.pow(x - startX, 2) + Math.pow(y - startY, 2));

            if (distance >= dragThreshold) {
                eventCallback(ClickEvent.HoverDrag(startX, startY, x, y));
            } else {
                eventCallback(ClickEvent.Hover(x, y));
            }

        } else {
            eventCallback(ClickEvent.Hover(x, y));
        }
    }

    public function setMouseUpCoordinates(x:Float, y:Float) {
        if (mousePressed) {
            mousePressed = false;

            final distance = Math.sqrt(Math.pow(x - startX, 2) + Math.pow(y - startY, 2));

            if (distance >= dragThreshold) {
                eventCallback(ClickEvent.DragCommit(startX, startY, x, y));
            } else {
                eventCallback(ClickEvent.PointCommit(x, y));
            }
        }
    }

    public function setMouseLeave() {
        mousePressed = false;
        eventCallback(ClickEvent.Canceled);
    }
}

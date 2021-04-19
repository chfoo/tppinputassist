package tppinputassist;

import js.jquery.JQuery;
import js.html.CanvasPattern;
import js.html.CanvasRenderingContext2D;
import js.html.CanvasElement;
import haxe.ds.StringMap;
import js.html.ButtonElement;
import js.Browser;
import js.html.DivElement;

using StringTools;


enum abstract DrawingButton(String) to String from String {
    var Touch = "touch";
    var Line = "line";
    var Curve = "curve";
    var Freehand = "freehand";
}

enum ActionButton  {
    Clear;
    Send;
}

enum abstract CurveMode(String) to String from String {
    var BezierVariableDegree = "BezierVariableDegree";
}

typedef Point = {x:Float, y:Float};

class DrawingTool {
    static final MAX_POINTS = 6;

    public var toolbarElement(default, null):DivElement;
    public var actionBarElement(default, null):DivElement;
    public var selectedTool(default, null):DrawingButton = DrawingButton.Touch;

    var toolbarButtons:StringMap<ButtonElement> = new StringMap();
    var containerElement:DivElement;
    var canvasElement:CanvasElement;
    var canvasContext:CanvasRenderingContext2D;
    var strokePattern:CanvasPattern;
    var handlePattern:CanvasPattern;
    var activeHandlePattern:CanvasPattern;
    var knots:Array<Handle> = [];
    var controlPoints:Array<Handle> = [];

    public function new() {
        initToolbar();
        initActionBar();
        initStrokePattern();
        initHandlePattern();
    }

    function initToolbar() {
        toolbarElement = Browser.document.createDivElement();

        addToolbarButton("👆T", DrawingButton.Touch);
        addToolbarButton("✒️📏L", DrawingButton.Line);
        addToolbarButton("✒️➰C", DrawingButton.Curve);
        // addToolbarButton("✏️F", DrawingButton.Freehand);

        updateVisualButtonSelect();
    }

    function initActionBar() {
        actionBarElement = Browser.document.createDivElement();

        addActionBarButton("Clear", ActionButton.Clear);
        // addActionBarButton("Send", ActionButton.Send);
    }

    function initStrokePattern() {
        final canvas = Browser.document.createCanvasElement();
        final context = canvas.getContext2d();
        canvas.width = 2;
        canvas.height = 2;
        context.imageSmoothingEnabled = false;
        context.fillStyle = "rgba(255, 255, 255, 0.8)";
        context.fillRect(0, 0, 1, 1);
        context.fillRect(1, 1, 1, 1);
        context.fillStyle = "rgba(0, 0, 0, 0.8)";
        context.fillRect(1, 0, 1, 1);
        context.fillRect(0, 1, 1, 1);

        strokePattern = context.createPattern(canvas, "repeat");
    }

    function initHandlePattern() {
        final canvas = Browser.document.createCanvasElement();
        final context = canvas.getContext2d();
        canvas.width = 2;
        canvas.height = 2;
        context.imageSmoothingEnabled = false;

        context.fillStyle = "rgba(0, 200, 200, 0.8)";
        context.fillRect(0, 0, 1, 1);
        context.fillRect(1, 1, 1, 1);
        context.fillStyle = "rgba(120, 100, 100, 0.8)";
        context.fillRect(1, 0, 1, 1);
        context.fillRect(0, 1, 1, 1);

        handlePattern = context.createPattern(canvas, "repeat");

        context.fillStyle = "rgba(200, 0, 200, 0.8)";
        context.fillRect(0, 0, 1, 1);
        context.fillRect(1, 1, 1, 1);
        context.fillStyle = "rgba(100, 120, 100, 0.8)";
        context.fillRect(1, 0, 1, 1);
        context.fillRect(0, 1, 1, 1);

        activeHandlePattern = context.createPattern(canvas, "repeat");
    }

    function addToolbarButton(label:String, tag:DrawingButton) {
        var button = Browser.document.createButtonElement();
        button.textContent = label;
        styleButton(button);

        if (tag == DrawingButton.Touch) {
            button.style.marginBottom = "0.4em";
        }

        button.onclick = () -> {
            if (selectedTool != tag) {
                selectedTool = tag;
                clearDrawingHandlesAndCanvas();
                updateVisualButtonSelect();
                toolbarButtonSelected();
            }
        };

        toolbarElement.appendChild(button);
        toolbarButtons.set(tag, button);
    }

    function styleButton(button:ButtonElement) {
        button.style.background = "rgba(10, 10, 10, 0.8)";
        button.style.border = "2px solid #333";
        button.style.borderRadius = "4px";
        button.style.display = "block";
        button.style.color = "#eee";
    }

    function addActionBarButton(label:String, tag:ActionButton) {
        var button = Browser.document.createButtonElement();
        button.textContent = label;
        styleButton(button);

        button.onclick = () -> {
            actionButtonSelected(tag);
        };

        actionBarElement.appendChild(button);
    }

    function updateVisualButtonSelect() {
        for (tag => button in toolbarButtons) {
            if (button.textContent.startsWith("►")) {
                button.textContent = button.textContent.substr(1);
            }

            if (tag == selectedTool) {
                button.textContent = '►${button.textContent}';
            }
        }
    }

    dynamic public function toolbarButtonSelected() {}

    dynamic public function changed() {}

    dynamic public function actionButtonSelected(button:ActionButton) {}

    public function setElements(container:DivElement, canvas:CanvasElement) {
        containerElement = container;
        canvasElement = canvas;
        canvasContext = canvas.getContext2d();
    }

    public function clearCanvas() {
        canvasContext.clearRect(0, 0, canvasElement.width, canvasElement.height);
    }

    public function clearDrawingHandlesAndCanvas() {
        for (handle in knots) {
            containerElement.removeChild(handle.element);
        }

        for (handle in controlPoints) {
            containerElement.removeChild(handle.element);
        }

        knots.resize(0);
        controlPoints.resize(0);
        clearCanvas();
    }

    public function pointsToString(useKnots:Bool, pointFormat:String, pointSeparator:String):String {
        var buf = new StringBuf();
        var handles = useKnots ? knots : controlPoints;

        for (handle in handles) {
            if (buf.length != 0) {
                buf.add(pointSeparator);
            }

            buf.add(pointFormat
                .replace("{x}", Std.string(Std.int(handle.x)))
                .replace("{y}", Std.string(Std.int(handle.y)))
            );
        }

        return buf.toString();
    }

    public function drawLine(x1:Float, y1:Float, x2:Float, y2:Float) {
        canvasContext.imageSmoothingEnabled = false;
        canvasContext.strokeStyle = strokePattern;
        canvasContext.beginPath();
        canvasContext.moveTo(x1 + 0.5, y1 + 0.5);
        canvasContext.lineTo(x2 + 0.5, y2 + 0.5);
        canvasContext.stroke();
    }

    public function addDrawHandle(x:Float, y:Float) {
        if (knots.length >= MAX_POINTS || controlPoints.length >= MAX_POINTS) {
            return;
        }

        switch selectedTool {
            case Touch:
                // pass
            case Line:
                addKnot(x, y);
            case Curve:
                addControlPoint(x, y);
            case Freehand:
                // TOOD
        }

        drawGraphics();
        changed();
    }

    function addKnot(x:Float, y:Float) {
        var handle = new Handle(x, y, true, handlePattern, activeHandlePattern);
        knots.push(handle);
        pushHandleToElement(handle);
    }

    function addControlPoint(x:Float, y:Float) {
        var handle = new Handle(x, y, false, handlePattern, activeHandlePattern);
        controlPoints.push(handle);
        pushHandleToElement(handle);
    }

    function pushHandleToElement(handle:Handle) {
        var divWidth = new JQuery(containerElement).width();
        var divHeight = new JQuery(containerElement).height();
        var x = Std.int(handle.x / canvasElement.width * divWidth - Handle.SIZE / 2.0);
        var y = Std.int(handle.y / canvasElement.height * divHeight - Handle.SIZE / 2.0);

        handle.element.style.position = "absolute";
        handle.element.style.left = '${x}px';
        handle.element.style.top = '${y}px';
        handle.element.style.cursor = "grabbing";
        handle.element.style.width = '${Handle.SIZE}px';
        handle.element.style.height = '${Handle.SIZE}px';

        var jq = new JQuery(handle.element);
        untyped jq.draggable({
            containment: containerElement,
            drag:
                (event, ui) -> {
                    updateHandleCoordinatesFromDrag(handle, ui.position);
                    drawGraphics();
                    changed();
                }
        });

        containerElement.appendChild(handle.element);
    }

    function updateHandleCoordinatesFromDrag(handle:Handle, position) {
        var divWidth = new JQuery(containerElement).width();
        var divHeight = new JQuery(containerElement).height();
        handle.x = Std.int((position.left + Handle.SIZE / 2.0) / divWidth * canvasElement.width);
        handle.y = Std.int((position.top + Handle.SIZE / 2.0) / divHeight * canvasElement.height);
    }

    public function drawGraphics() {
        clearCanvas();
        switch selectedTool {
            case Touch:
                // pass
            case Line:
                drawLineModeGraphics();
            case Curve:
                drawCurveModeGraphics();
            case Freehand:
                // TOOD
        }
    }

    function drawLineModeGraphics() {
        canvasContext.imageSmoothingEnabled = false;
        canvasContext.strokeStyle = strokePattern;
        canvasContext.beginPath();

        for (index in 0...knots.length) {
            var point = knots[index];

            if (index == 0) {
                canvasContext.moveTo(point.x + 0.5, point.y + 0.5);
            } else {
                canvasContext.lineTo(point.x + 0.5, point.y + 0.5);
            }
        }

        canvasContext.stroke();
    }

    function drawCurveModeGraphics() {
        drawLinesConnectingControlPoints();
        drawBezierVariableDegree();
    }

    function drawLinesConnectingControlPoints() {
        canvasContext.imageSmoothingEnabled = false;
        canvasContext.strokeStyle = handlePattern;
        canvasContext.beginPath();

        for (index in 0...controlPoints.length) {
            var point = controlPoints[index];

            if (index == 0) {
                canvasContext.moveTo(point.x + 0.5, point.y + 0.5);
            } else {
                canvasContext.lineTo(point.x + 0.5, point.y + 0.5);
            }
        }

        canvasContext.stroke();
    }

    function drawBezierVariableDegree() {
        var t = 0.0;

        var points = [
            for (handle in controlPoints) { x: handle.x, y: handle.y }
        ];

        canvasContext.imageSmoothingEnabled = false;
        canvasContext.strokeStyle = strokePattern;
        canvasContext.beginPath();

        while (t <= 1.0) {
            var point = generic_bezier_curve(t, points);

            if (t == 0.0) {
                canvasContext.moveTo(point.x + 0.5, point.y + 0.5);
            } else {
                canvasContext.lineTo(point.x + 0.5, point.y + 0.5);
            }

            t += 0.05;
        }

        canvasContext.stroke();
    }

    static function generic_bezier_curve(t:Float, points:Array<Point>):Point {
        if (points.length == 1) {
            return points[0];
        } else {
            var point1 = generic_bezier_curve(t, points.slice(0, -1));
            var point2 = generic_bezier_curve(t, points.slice(1));

            return lerp_point(t, point1, point2);
        }
    }

    static function lerp_point(t:Float, point1:Point, point2:Point):Point {
        return {
            x: (1.0 - t) * point1.x + t * point2.x,
            y: (1.0 - t) * point1.y + t * point2.y,
        };
    }
}

class Handle {
    public static final SIZE = 10;

    public var x:Float = 0.0;
    public var y:Float = 0.0;
    public var element(default, null):CanvasElement;
    var isKnot:Bool;
    var pattern:CanvasPattern;
    var activePattern:CanvasPattern;

    public function new(x:Float, y:Float, isKnot:Bool, pattern:CanvasPattern, activePattern:CanvasPattern) {
        this.x = x;
        this.y = y;
        this.isKnot = isKnot;

        this.pattern = pattern;
        this.activePattern = pattern;

        element = Browser.document.createCanvasElement();
        element.width = SIZE;
        element.height = SIZE;

        draw(false);
    }

    function draw(active:Bool) {
        if (isKnot) {
            drawKnot(active);
        } else {
            drawControlPoint(active);
        }
    }

    function drawKnot(active:Bool) {
        var context = element.getContext2d();

        context.clearRect(0, 0, SIZE, SIZE);

        context.imageSmoothingEnabled = false;
        context.fillStyle = active ? activePattern : pattern;
        context.beginPath();
        context.rect(0.5, 0.5, SIZE - 1, SIZE - 1);
        context.fill();
    }

    function drawControlPoint(active:Bool) {
        var context = element.getContext2d();

        context.clearRect(0, 0, SIZE, SIZE);

        context.imageSmoothingEnabled = false;
        context.fillStyle = active ? activePattern : pattern;
        context.beginPath();
        context.arc(SIZE / 2.0, SIZE / 2.0, SIZE / 2.0, 0.0, 2.0 * Math.PI);
        context.fill();
    }
}

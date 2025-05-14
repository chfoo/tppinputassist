package tppinputassist;

import js.Browser;


class Main {
    static var NAMESPACE = 'tppinputassist';

    static public function main() {
        if (Reflect.hasField(Browser.document, Main.NAMESPACE)) {
            return;
        }

        Reflect.setField(Browser.document, Main.NAMESPACE, true);

        var app = new App();
        app.run();
    }

    static private function __init__() {
        js.Syntax.code("var $ = jQuery;");
    }
}

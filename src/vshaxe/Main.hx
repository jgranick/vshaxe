package vshaxe;

import Vscode.*;
import vscode.*;

class Main {
    public static var instance:Main;
    public var server:LanguageServer;

    function new(context:ExtensionContext, ?onReadyCallback) {
        new InitProject(context);
        server = new LanguageServer(context, onReadyCallback);
        new Commands(context, server);

        setLanguageConfiguration();
        server.start();
    }

    function setLanguageConfiguration() {
        var defaultWordPattern = "(-?\\d*\\.\\d\\w*)|([^\\`\\~\\!\\@\\#\\%\\^\\&\\*\\(\\)\\-\\=\\+\\[\\{\\]\\}\\\\\\|\\;\\:\\'\\\"\\,\\.\\<\\>\\/\\?\\s]+)";
        var wordPattern = defaultWordPattern + "|(@:\\w*)"; // metadata
        languages.setLanguageConfiguration("Haxe", {wordPattern: new js.RegExp(wordPattern)});
    }

    @:keep
    @:expose("activate")
    static function main(context:ExtensionContext) {
        var api = new Api();
        init(context, api);
        return api;
    }

    static function init(context:ExtensionContext, api:Api) {
        instance = new Main(context, api.onReadyCallback);
    }
}

@:keep class Api {
    public var isReady(get, null):Bool;

    public function new() {}

    public dynamic function onReady():Void {} // TODO: Support multiple listeners?

    public function onReadyCallback():Void {
        onReady();
    }

    public function updateDisplayArguments(args:Array<String>):Void {
        if (Main.instance != null && isReady) {
            Main.instance.server.updateDisplayArguments(args);
        }
    }

    function get_isReady():Bool {
        if (Main.instance != null) {
            return Main.instance.server.isReady;
        } else {
            return false;
        }
    }
}
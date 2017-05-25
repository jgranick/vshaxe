package vshaxe;

import Vscode.*;
import vscode.*;
import vshaxe.projectTypes.*;

class LanguageServer {
    var context:ExtensionContext;
    var clientDisposable:Disposable;
    var hxFileWatcher:FileSystemWatcher;
    var targetDropDown:DropDown;
    var modeDropDown:DropDown;
    var projectTypeAdapter:ProjectTypeAdapter;
    var projectType(get, never):String;
    var taskDisposable:Disposable;

    public var client(default, null):LanguageClient;

    public function new(context:ExtensionContext) {
        this.context = context;

        targetDropDown = new DropDown(context, "haxe.selectDisplayConfiguration", "haxe.displayConfigurationIndex", 5);
        modeDropDown = new DropDown(context, "haxe.selectMode", "haxe.modeIndex", 4);
        createProjectTypeAdapter();

        context.subscriptions.push(workspace.onDidChangeConfiguration(onDidChangeConfiguration));
        context.subscriptions.push(window.onDidChangeActiveTextEditor(onDidChangeActiveTextEditor));
    }

    function get_projectType() return workspace.getConfiguration("haxe").get("projectType");

    function onDidChangeConfiguration(_) {
        if (projectTypeAdapter == null || projectTypeAdapter.getName().toLowerCase() != projectType) {
            createProjectTypeAdapter();
        }
    }

    function createProjectTypeAdapter() {
        if (taskDisposable != null)
            taskDisposable.dispose();

        var displayConfigurations = workspace.getConfiguration("haxe").get("displayConfigurations");
        projectTypeAdapter = switch (projectType) {
            case "haxe": new HaxeAdapter(displayConfigurations, targetDropDown.getIndex(), modeDropDown.getIndex());
            case "lime": new LimeAdapter(displayConfigurations, targetDropDown.getIndex(), modeDropDown.getIndex());
            case _: throw "invalid project type " + projectType; // TODO: better error handling
        }
        var projectType = projectTypeAdapter.getName();
        targetDropDown.update('$$(gear) $projectType:', projectType, projectTypeAdapter.getTargets());
        modeDropDown.update('', projectType, projectTypeAdapter.getModes());
        taskDisposable = workspace.registerTaskProvider(projectTypeAdapter);
    }

    function onDidChangeActiveTextEditor(editor:TextEditor) {
        if (editor != null && editor.document.languageId == "haxe")
            client.sendNotification({method: "vshaxe/didChangeActiveTextEditor"}, {uri: editor.document.uri.toString()});
    }

    public function start() {
        var serverModule = context.asAbsolutePath("./server_wrapper.js");
        var serverOptions = {
            run: {module: serverModule, options: {env: js.Node.process.env}},
            debug: {module: serverModule, options: {env: js.Node.process.env, execArgv: ["--nolazy", "--debug=6004"]}}
        };
        var clientOptions = {
            documentSelector: "haxe",
            synchronize: {
                configurationSection: "haxe"
            },
            initializationOptions: {
                displayConfiguration: projectTypeAdapter.getDisplayArguments()
            }
        };
        client = new LanguageClient("haxe", "Haxe", serverOptions, clientOptions);
        client.logFailedRequest = function(type, error) {
            client.warn('Request ${type.method} failed.', error);
        };
        client.onReady().then(function(_) {
            client.outputChannel.appendLine("Haxe language server started");
            function updateDisplayArguments() {
                client.sendNotification({method: "vshaxe/didChangeDisplayArguments"}, {arguments: projectTypeAdapter.getDisplayArguments()});
            }
            targetDropDown.onDidChangeIndex = function(index) {
                projectTypeAdapter.onDidChangeDisplayConfigurationIndex(index);
                updateDisplayArguments();
            }
            modeDropDown.onDidChangeIndex = function(index) {
                projectTypeAdapter.onDidChangeModeIndex(index);
                updateDisplayArguments();
            }

            hxFileWatcher = workspace.createFileSystemWatcher("**/*.hx", false, true, true);
            context.subscriptions.push(hxFileWatcher.onDidCreate(function(uri) {
                var editor = window.activeTextEditor;
                if (editor == null || editor.document.uri.fsPath != uri.fsPath)
                    return;
                if (editor.document.getText(new Range(0, 0, 0, 1)).length > 0) // skip non-empty created files (can be created by e.g. copy-pasting)
                    return;

                client.sendRequest({method: "vshaxe/determinePackage"}, {fsPath: uri.fsPath}).then(function(result:{pack:String}) {
                    if (result.pack == "")
                        return;
                    editor.edit(function(edit) edit.insert(new Position(0, 0), 'package ${result.pack};\n\n'));
                });
            }));
            context.subscriptions.push(hxFileWatcher);

            client.onNotification({method: "vshaxe/progressStart"}, startProgress);
            client.onNotification({method: "vshaxe/progressStop"}, stopProgress);

            #if debug
            client.onNotification({method: "vshaxe/updateParseTree"}, function(result:{uri:String, parseTree:String}) {
                commands.executeCommand("hxparservis.updateParseTree", result.uri, result.parseTree);
            });
            #end
        });
        clientDisposable = client.start();
        context.subscriptions.push(clientDisposable);
    }

    var progresses = new Map<Int, Void->Void>();

    function startProgress(data:{id:Int, title:String}) {
        window.withProgress({location: Window, title: data.title}, function(_) {
            return new js.Promise(function(resolve, _) {
                progresses[data.id] = function() resolve(null);
            });
        });
    }

    function stopProgress(data:{id:Int}) {
        var stop = progresses[data.id];
        if (stop != null) {
            progresses.remove(data.id);
            stop();
        }
    }

    public function restart() {
        if (client != null && client.outputChannel != null)
            client.outputChannel.dispose();

        if (clientDisposable != null) {
            context.subscriptions.remove(clientDisposable);
            clientDisposable.dispose();
            clientDisposable = null;
        }
        if (hxFileWatcher != null) {
            context.subscriptions.remove(hxFileWatcher);
            hxFileWatcher.dispose();
            hxFileWatcher = null;
        }

        for (stop in progresses) {
            stop();
        }
        progresses = new Map();

        start();
    }
}
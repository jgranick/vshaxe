package vshaxe;

import vscode.ExtensionContext;
import vscode.QuickPickItem;
import vscode.StatusBarItem;
import Vscode.*;

class DropDown {
    var context:ExtensionContext;
    var statusBarItem:StatusBarItem;
    var label:String = "";
    var projectType:String = "Haxe";
    var options:Array<String> = [];
    var workspaceStateName:String;

    public function new(context:ExtensionContext, commandName:String, workspaceStateName:String, priority:Int) {
        this.context = context;
        this.workspaceStateName = workspaceStateName;

        statusBarItem = window.createStatusBarItem(Left, priority);
        statusBarItem.tooltip = "Select Haxe configuration";
        statusBarItem.command = commandName;
        context.subscriptions.push(statusBarItem);

        context.subscriptions.push(commands.registerCommand(commandName, selectConfiguration));

        context.subscriptions.push(workspace.onDidChangeConfiguration(onDidChangeConfiguration));
        context.subscriptions.push(window.onDidChangeActiveTextEditor(onDidChangeActiveTextEditor));
    }

    public function update(label:String, projectType:String, options:Array<String>) {
        this.label = label;
        this.projectType = projectType;
        this.options = options;
        fixIndex();
        updateStatusBarItem();
    }

    function fixIndex() {
        var index = getIndex();
        if (options == null || index >= options.length)
            setIndex(0);
    }

    function selectConfiguration() {
        if (options == null || options.length == 0) {
            window.showErrorMessage("No Haxe display configurations are available. Please provide the haxe.displayConfigurations setting.", ({title: "Edit settings"} : vscode.MessageItem)).then(function(button) {
                if (button == null)
                    return;
                workspace.openTextDocument(workspace.rootPath + "/.vscode/settings.json").then(function(doc) window.showTextDocument(doc));
            });
            return;
        }
        if (options.length == 1) {
            window.showInformationMessage("Only one Haxe display configuration found: " + options[0]);
            return;
        }

        var items:Array<IndexedPickItem> = [];
        for (index in 0...options.length) {
            items.push({
                label: options[index],
                description: "",
                index: index,
            });
        }

        window.showQuickPick(items, {placeHolder: 'Select $projectType configuration'}).then(function(choice:IndexedPickItem) {
            if (choice == null || choice.index == getIndex())
                return;
            setIndex(choice.index);
        });
    }

    function onDidChangeConfiguration(_) {
        fixIndex();
        updateStatusBarItem();
    }

    function onDidChangeActiveTextEditor(_) {
        updateStatusBarItem();
    }

    function updateStatusBarItem() {
        if (window.activeTextEditor == null) {
            statusBarItem.hide();
            return;
        }

        if (languages.match({language: 'haxe', scheme: 'file'}, window.activeTextEditor.document) > 0) {
            if (options != null && options.length >= 2) {
                var index = getIndex();
                statusBarItem.text = '$label ${options[index]}';
                statusBarItem.show();
                return;
            }
        }

        statusBarItem.hide();
    }

    public inline function getIndex():Int {
        return context.workspaceState.get(workspaceStateName, 0);
    }

    function setIndex(index:Int) {
        context.workspaceState.update(workspaceStateName, index);
        updateStatusBarItem();
        onDidChangeIndex(index);
    }

    public dynamic function onDidChangeIndex(index:Int):Void {}
}

private typedef IndexedPickItem = {
    >QuickPickItem,
    var index:Int;
}

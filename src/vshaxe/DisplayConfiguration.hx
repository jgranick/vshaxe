package vshaxe;

import vscode.ExtensionContext;
import vscode.QuickPickItem;
import vscode.StatusBarItem;
import Vscode.*;

class DisplayConfiguration {
    var context:ExtensionContext;
    var statusBarItem:StatusBarItem;
    var projectType:String = "Haxe";
    var targets:Array<String> = [];

    public function new(context:ExtensionContext) {
        this.context = context;

        statusBarItem = window.createStatusBarItem(Left);
        statusBarItem.tooltip = "Select Haxe configuration";
        statusBarItem.command = "haxe.selectDisplayConfiguration";
        context.subscriptions.push(statusBarItem);

        context.subscriptions.push(commands.registerCommand("haxe.selectDisplayConfiguration", selectConfiguration));

        context.subscriptions.push(workspace.onDidChangeConfiguration(onDidChangeConfiguration));
        context.subscriptions.push(window.onDidChangeActiveTextEditor(onDidChangeActiveTextEditor));
    }

    public function update(projectType:String, targets:Array<String>) {
        this.projectType = projectType;
        this.targets = targets;
        fixIndex();
        updateStatusBarItem();
    }

    function fixIndex() {
        var index = getIndex();
        if (targets == null || index >= targets.length)
            setIndex(0);
    }

    function selectConfiguration() {
        if (targets == null || targets.length == 0) {
            window.showErrorMessage("No Haxe display configurations are available. Please provide the haxe.displayConfigurations setting.", ({title: "Edit settings"} : vscode.MessageItem)).then(function(button) {
                if (button == null)
                    return;
                workspace.openTextDocument(workspace.rootPath + "/.vscode/settings.json").then(function(doc) window.showTextDocument(doc));
            });
            return;
        }
        if (targets.length == 1) {
            window.showInformationMessage("Only one Haxe display configuration found: " + targets[0]);
            return;
        }

        var items:Array<DisplayConfigurationPickItem> = [];
        for (index in 0...targets.length) {
            items.push({
                label: targets[index],
                description: "",
                index: index,
            });
        }

        window.showQuickPick(items, {placeHolder: 'Select $projectType configuration'}).then(function(choice:DisplayConfigurationPickItem) {
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
            if (targets != null && targets.length >= 2) {
                var index = getIndex();
                statusBarItem.text = '$(gear) $projectType: ${targets[index]}';
                statusBarItem.show();
                return;
            }
        }

        statusBarItem.hide();
    }

    public inline function getIndex():Int {
        return context.workspaceState.get("haxe.displayConfigurationIndex", 0);
    }

    function setIndex(index:Int) {
        context.workspaceState.update("haxe.displayConfigurationIndex", index);
        updateStatusBarItem();
        onDidChangeIndex(index);
    }

    public dynamic function onDidChangeIndex(index:Int):Void {}
}

private typedef DisplayConfigurationPickItem = {
    >QuickPickItem,
    var index:Int;
}

package vshaxe;

import vscode.ExtensionContext;
import vscode.QuickPickItem;
import vscode.StatusBarItem;
import Vscode.*;
import vshaxe.projectTypes.*;
using vshaxe.helper.ArrayHelper;

class ProjectConfiguration {
    var context:ExtensionContext;
    var statusBarItem:StatusBarItem;
    var configurationList:Array<ProjectConfigurationItem>;
    var configurationListByID:Map<String, ProjectConfigurationItem>;
    var configurations = new Map<String, AbstractProjectType>();
    var configuration:AbstractProjectType;

    public function new(context:ExtensionContext) {
        this.context = context;
        configurationList = [
            {
                id: "hxml",
                label: "HXML",
                description: "Standard Haxe project using HXML files",
                type: HXMLProjectType.new
            },
            {
                id: "lime",
                label: "Lime",
                description: "Project using Lime/OpenFL command-line tools",
                type: LimeProjectType.new
            }
        ];

        configurationListByID = new Map();
        for (item in configurationList) {
            configurationListByID[item.id] = item;
        }

        statusBarItem = window.createStatusBarItem(Left);
        statusBarItem.tooltip = "Select Project Configuration";
        statusBarItem.command = "haxe.selectProjectConfiguration";
        context.subscriptions.push(statusBarItem);

        context.subscriptions.push(commands.registerCommand("haxe.selectProjectConfiguration", selectConfiguration));

        context.subscriptions.push(workspace.onDidChangeConfiguration(onDidChangeConfiguration));
        context.subscriptions.push(window.onDidChangeActiveTextEditor(onDidChangeActiveTextEditor));

        fixID();
        updateStatusBarItem();
        configuration = getConfiguration();
    }

    function fixID() {
        var id = getID();
        if (!configurationListByID.exists(id)) {
            setID("hxml");
        }
    }

    function selectConfiguration() {
        window.showQuickPick(configurationList, {matchOnDescription: true, placeHolder: "Select Project Configuration"}).then(function(choice:ProjectConfigurationItem) {
            if (choice == null || choice.id == getID())
                return;
            setID(choice.id);
        });
    }

    function onDidChangeConfiguration(_) {
        fixID();
        updateStatusBarItem();
        checkConfigurationChange();
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
            statusBarItem.text = configurationListByID[getID()].label;
            statusBarItem.show();
            return;
        }

        statusBarItem.hide();
    }

    public inline function getConfiguration():AbstractProjectType {
        var id = getID();
        if (configuration != null && configuration.id != id) {
            configuration.disable();
        }

        if (!configurations.exists(id)) {
            configuration = configurationListByID[id].type(context);
            configurations[id] = configuration;
            configuration.enable();
        } else if (configuration.id != id) {
            configuration = configurations[id];
            configuration.enable();
        }

        return configuration;
    }

    public inline function getID():String {
        return context.workspaceState.get("haxe.projectConfigurationID", "hxml");
    }

    function setID(id:String) {
        context.workspaceState.update("haxe.projectConfigurationID", id);
        updateStatusBarItem();
        //onDidChangeIndex(index);
        checkConfigurationChange();
    }

    function checkConfigurationChange() {
        var cacheConfiguration = configuration;
        getConfiguration();
        if (cacheConfiguration != configuration) {
            //onDidChangeDisplayConfiguration(newConfiguration);
        }
    }

    public dynamic function onDidChangeIndex(index:Int):Void {}

    public dynamic function onDidChangeDisplayConfiguration(configuration:Array<String>):Void {}
}

private typedef ProjectConfigurationItem = {
    >QuickPickItem,
    var id:String;
    var type:ExtensionContext->AbstractProjectType;
}
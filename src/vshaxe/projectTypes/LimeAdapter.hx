package vshaxe.projectTypes;

import js.node.Buffer;
import js.node.ChildProcess;
import vscode.*;

private enum LimeCommand {
    Update;
    Display;
    Test;
    Build;
    Run;
    Clean;
}

class LimeAdapter extends ProjectTypeAdapter {
    var targets:Array<String>;
    var modes:Array<String>;
    var arguments:Array<String>;
    var target:String;
    var projectFile:String;

    public function new(displayConfigurations:Array<Array<String>>, displayConfigurationIndex:Int, modeIndex:Int) {
        super(displayConfigurations, displayConfigurationIndex, modeIndex);

        targets = [
            "Flash",
            "HTML5",
            "Neko",
            "Android"
        ];

        switch (Sys.systemName()) {
            case "Windows":
                targets.push("Windows");
            case "Linux":
                targets.push("Linux");
            case "Mac":
                targets.push("Mac");
                targets.push("iOS");
                targets.push("tvOS");
        }

        modes = [
            "debug",
            "release",
            "final"
        ];
    }

    override public function getName() return "Lime";

    override public function getTargets() return targets;

    override public function getModes() return modes;

    override public function getDisplayArguments():Array<String> {
        if (arguments == null)
            arguments = refreshArguments();
        return arguments;
    }

    override public function onDidChangeDisplayConfigurationIndex(index:Int) {
        super.onDidChangeDisplayConfigurationIndex(index);
        arguments = null;
    }

    override public function onDidChangeModeIndex(index:Int) {
        super.onDidChangeModeIndex(index);
        arguments = null;
    }

    function refreshArguments():Array<String> {
        projectFile = displayConfigurations[0][0]; // meh
        target = targets[displayConfigurationIndex].toLowerCase();
        runCommand("haxelib", getLimeArguments(Update));
        // TODO: escape projectFile path?
        var result:String = runCommand("haxelib", getLimeArguments(Display));
        // TODO: hxml parser? if there are spaces in paths, we have a problem
        var arguments = ~/[ \n]/g.split(result);
        return arguments.filter(function(arg) return arg.length > 0);
    }

    function runCommand(command:String, args:Array<String>):String {
        var commandLine = command + " " + args.join(" ");
        var result:Buffer = ChildProcess.execSync(commandLine);
        return result.toString();
    }

    override public function provideTasks(token:CancellationToken):ProviderResult<Array<Task>> {
        return [
            createTask(Test, Test),
            createTask(Build, Build),
            createTask(Run),
            createTask(Clean, Clean)
        ];
    }

    function createTask(command:LimeCommand, ?group:TaskGroup) {
        var commandName = Std.string(command).toLowerCase();
        var task = new ProcessTask('lime $commandName $target', "haxelib", getLimeArguments(command));
        if (group != null)
            task.group = group;
        // TODO: problem matcher
        return task;
    }

    function getLimeArguments(command:LimeCommand) {
        var arguments = ["run", "lime", Std.string(command).toLowerCase(), projectFile, target];
        var mode = modes[modeIndex];
        switch (mode) {
            case "debug" | "final": arguments.push('-$mode');
            case _:
        }
        return arguments;
    }
}
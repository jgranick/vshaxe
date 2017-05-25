package vshaxe.projectTypes;

import js.node.Buffer;
import js.node.ChildProcess;
import vscode.*;

class LimeAdapter extends ProjectTypeAdapter {
    var targets:Array<String>;
    var arguments:Array<String>;
    var target:String;
    var projectFile:String;

    public function new(displayConfigurations:Array<Array<String>>, displayConfigurationIndex:Int) {
        super(displayConfigurations, displayConfigurationIndex);

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
    }

    override public function getName() return "Lime";

    override public function getTargets():Array<String> {
        return targets;
    }

    override public function getDisplayArguments():Array<String> {
        if (arguments == null)
            arguments = refreshArguments();
        return arguments;
    }

    override public function onDidChangeDisplayConfigurationIndex(index:Int) {
        super.onDidChangeDisplayConfigurationIndex(index);
        arguments = null;
    }

    function refreshArguments():Array<String> {
        projectFile = displayConfigurations[0][0]; // meh
        target = targets[displayConfigurationIndex].toLowerCase();
        runCommand("haxelib", getLimeArguments("update"));
        // TODO: escape projectFile path?
        var result:String = runCommand("haxelib", getLimeArguments("display"));
        // TODO: hxml parser? if there are spaces in paths, we have a problem
        var arguments = ~/[ \n]/g.split(result);
        return arguments.filter(function(arg) return arg.length > 0);
    }

    function runCommand(command:String, args:Array<String>):String {
        var commandLine = command + " " + args.join(" ");
        trace(commandLine); // TODO: some verbose setting
        var result:Buffer = ChildProcess.execSync(commandLine);
        trace(result.toString());
        return result.toString();
    }

    override public function provideTasks(token:CancellationToken):ProviderResult<Array<Task>> {
        return [
            createTask("test", Test),
            createTask("build", Build),
            createTask("run"),
            createTask("clean", Clean)
        ];
    }

    function createTask(command:String, ?group:TaskGroup) {
        var task = new ProcessTask('lime $command $target', "haxelib", getLimeArguments(command));
        if (group != null)
            task.group = group;
        // TODO: problem matcher
        return task;
    }

    function getLimeArguments(command:String) {
        return ["run", "lime", command, projectFile, target];
    }
}
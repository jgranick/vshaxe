package builders;

class VSCodeTasksBuilder implements IBuilder {
    var cli:CliTools;

    public function new(cli) {
        this.cli = cli;
    }

    public function build(config:Config) {
        var base = Reflect.copy(template);
        for (target in config.targets) {
            var targetArgs = config.project.targets.getTarget(target);
            base.tasks = buildTask(config.project, targetArgs, false).concat(buildTask(config.project, targetArgs, true));
        }
        base.tasks = base.tasks.filterDuplicates(function(t1, t2) return t1.taskName == t2.taskName);

        var tasksJson = haxe.Json.stringify(base, null, "    ");
        tasksJson = '// ${Warning.Message}\n$tasksJson';
        cli.saveContent(".vscode/tasks.json", tasksJson);
    }

    static var problemMatcher = {
        owner: "haxe",
        pattern: {
            "regexp": "^(.+):(\\d+): (?:lines \\d+-(\\d+)|character(?:s (\\d+)-| )(\\d+)) : (?:(Warning) : )?(.*)$",
            "file": 1,
            "line": 2,
            "endLine": 3,
            "column": 4,
            "endColumn": 5,
            "severity": 6,
            "message": 7
        }
    }

    static var template = {
        version: "0.1.0",
        command: "haxe",
        suppressTaskName: true,
        tasks: [],
        _runner: "terminal"
    }

    function buildTask(project:Project, config:TargetArguments, debug:Bool):Array<Task> {
        var suffix = "";
        if (!config.impliesDebug && debug) suffix = " (debug)";

        var task:Task = {
            taskName: '${config.name}$suffix',
            args: ["--run", "Build", "-t", config.name],
            problemMatcher: problemMatcher
        }

        if (config.impliesDebug || debug) {
            if (config.isBuildCommand) {
                task.isBuildCommand = true;
                task.taskName += " - BUILD";
            }
            if (config.isTestCommand) {
                task.isTestCommand = true;
                task.taskName += " - TEST";
            }
            task.args.push("--debug");
        }

        return [task].concat(config.targetDependencies.get().flatMap(
            function(s) return buildTask(project, project.targets.getTarget(s), debug)
        ));
    }
}

typedef Task = {
    var taskName:String;
    var args:Array<String>;
    var problemMatcher:{};
    @:optional var isBuildCommand:Bool;
    @:optional var isTestCommand:Bool;
}
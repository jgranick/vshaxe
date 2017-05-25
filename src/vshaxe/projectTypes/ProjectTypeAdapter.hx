package vshaxe.projectTypes;

import vscode.*;

class ProjectTypeAdapter {
    var displayConfigurations:Array<Array<String>>;
    var displayConfigurationIndex:Int;

    public function new(displayConfigurations:Array<Array<String>>, displayConfigurationIndex:Int) {
        this.displayConfigurations = displayConfigurations;
        this.displayConfigurationIndex = displayConfigurationIndex;
    }

    public function onDidChangeDisplayConfigurationIndex(index:Int) {
        displayConfigurationIndex = index;
    }

    public function getName():String throw "abstract method";

    public function getTargets():Array<String> throw "abstract method";

    public function getDisplayArguments():Array<String> throw "abstract method";

    public function provideTasks(token:CancellationToken):ProviderResult<Array<Task>> throw "abstract method";
}
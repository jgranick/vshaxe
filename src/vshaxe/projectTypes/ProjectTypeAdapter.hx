package vshaxe.projectTypes;

import vscode.*;

class ProjectTypeAdapter {
    var displayConfigurations:Array<Array<String>>;
    var displayConfigurationIndex:Int;
    var modeIndex:Int;

    public function new(displayConfigurations:Array<Array<String>>, displayConfigurationIndex:Int, modeIndex:Int) {
        this.displayConfigurations = displayConfigurations;
        this.displayConfigurationIndex = displayConfigurationIndex;
        this.modeIndex = modeIndex;
    }

    public function onDidChangeDisplayConfigurationIndex(index:Int) {
        displayConfigurationIndex = index;
    }

    public function onDidChangeModeIndex(index:Int) {
        modeIndex = index;
    }

    public function getName():String throw "abstract method";

    public function getTargets():Array<String> throw "abstract method";

    public function getModes():Array<String> throw "abstract method";

    public function getDisplayArguments():Array<String> throw "abstract method";

    public function provideTasks(token:CancellationToken):ProviderResult<Array<Task>> throw "abstract method";
}
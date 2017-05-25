package vshaxe.projectTypes;

import vscode.*;

class HaxeAdapter extends ProjectTypeAdapter {
    override public function getName() return "Haxe";

    override public function getTargets():Array<String> {
        return displayConfigurations.map(function(config) return config.join(" "));
    }

    override public function getDisplayArguments():Array<String> {
        return displayConfigurations[displayConfigurationIndex];
    }

    override public function provideTasks(token:CancellationToken):ProviderResult<Array<Task>> {
        return [
        ];
    }

    override public function getModes():Array<String> {
        return [
        ];
    }
}
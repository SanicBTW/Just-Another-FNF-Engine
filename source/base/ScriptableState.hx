package base;

import backend.Controls;
import backend.ScriptHandler.ForeverModule;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import transitions.FadeTransition;

// Holds the transitions, controls and language (soon)
class ScriptableState extends FlxState implements ModuleManager
{
	private var moduleBatch:Array<ForeverModule> = [];

	override function create()
	{
		if (!FadeTransition.skipTransOut)
			openSubState(new FadeTransition(0.7, true));

		FadeTransition.skipTransOut = false;

		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
		super.create();
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		callOnModules('destroy', null);

		super.destroy();
	}

	public static function switchState(nextState:FlxState)
	{
		var curState:ScriptableState = cast FlxG.state;
		if (!FadeTransition.skipTransIn)
		{
			curState.openSubState(new FadeTransition(0.6, false));
			FadeTransition.finishCallback = function()
			{
				if (nextState == curState)
					FlxG.resetState();
				else
					FlxG.switchState(nextState);
			};
			return;
		}
		FadeTransition.skipTransIn = false;
		FlxG.switchState(nextState);
	}

	private function onActionPressed(action:String) {}

	private function onActionReleased(action:String) {}

	private function callOnModules(event:String, args:Dynamic)
	{
		for (module in moduleBatch)
		{
			if (module.active && module.exists(event))
				module.get(event)(args);
		}
	}

	private function setOnModules(variable:String, arg:Dynamic)
	{
		for (module in moduleBatch)
		{
			if (module.active)
				module.set(variable, arg);
		}
	}
}

class ScriptableSubState extends FlxSubState implements ModuleManager
{
	private var moduleBatch:Array<ForeverModule> = [];

	override function create()
	{
		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
		super.create();
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		callOnModules('destroy', null);

		super.destroy();
	}

	private function onActionPressed(action:String) {}

	private function onActionReleased(action:String) {}

	private function callOnModules(event:String, args:Dynamic)
	{
		for (module in moduleBatch)
		{
			if (module.active && module.exists(event))
				module.get(event)(args);
		}
	}

	private function setOnModules(variable:String, arg:Dynamic)
	{
		for (module in moduleBatch)
		{
			if (module.active)
				module.set(variable, arg);
		}
	}
}

// Totally not a ripoff FunkinLua from Psych Engine (its 3 am leave me alone)

interface ModuleManager
{
	// Array that contains all of the loaded modules (automatically pushed through ScriptHandler.loadModule)
	private var moduleBatch:Array<ForeverModule>;

	// Will only execute the active modules
	private function callOnModules(event:String, args:Dynamic):Void;
	private function setOnModules(variable:String, arg:Dynamic):Void;
}

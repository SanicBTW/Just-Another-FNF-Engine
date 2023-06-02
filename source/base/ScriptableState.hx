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

	// dumbass
	public static function resetState()
	{
		var curState:ScriptableState = cast FlxG.state;
		if (!FadeTransition.skipTransIn)
		{
			curState.openSubState(new FadeTransition(0.6, false));
			FadeTransition.finishCallback = function()
			{
				FlxG.resetState();
			};
			return;
		}
		FadeTransition.skipTransIn = false;
		FlxG.resetState();
	}

	private function onActionPressed(action:String) {}

	private function onActionReleased(action:String) {}

	public function callOnModules(event:String, args:Dynamic)
	{
		try
		{
			for (module in moduleBatch)
			{
				if (module.active && module.exists(event))
					module.get(event)(args);
			}
		}
		catch (ex)
		{
			trace('Failed to execute $event on modules ($ex)');
		}
	}

	public function setOnModules(variable:String, arg:Dynamic)
	{
		try
		{
			for (module in moduleBatch)
			{
				if (module.active)
					module.set(variable, arg);
			}
		}
		catch (ex)
		{
			trace('Failed to set $variable on modules ($ex)');
		}
	}
}

class ScriptableSubState extends FlxSubState
{
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

	// It will use the current state module batch
	public function callOnModules(event:String, args:Dynamic)
	{
		@:privateAccess
		{
			try
			{
				for (module in cast(FlxG.state, ScriptableState).moduleBatch)
				{
					if (module.active && module.exists(event))
						module.get(event)(args);
				}
			}
			catch (ex)
			{
				trace('Failed to execute $event on modules ($ex)');
			}
		}
	}

	public function setOnModules(variable:String, arg:Dynamic)
	{
		@:privateAccess
		{
			try
			{
				for (module in cast(FlxG.state, ScriptableState).moduleBatch)
				{
					if (module.active)
						module.set(variable, arg);
				}
			}
			catch (ex)
			{
				trace('Failed to set $variable on modules ($ex)');
			}
		}
	}
}

// Totally not a ripoff FunkinLua from Psych Engine (its 3 am leave me alone)

interface ModuleManager
{
	// Array that contains all of the loaded modules (automatically pushed through ScriptHandler.loadModule)
	private var moduleBatch:Array<ForeverModule>;

	// Will only execute the active modules
	public function callOnModules(event:String, args:Dynamic):Void;
	public function setOnModules(variable:String, arg:Dynamic):Void;
}

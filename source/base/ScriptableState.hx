package base;

import base.system.Controls;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUISubState;

// From FNF-Forever-Engine (My fork)
class ScriptableState extends FlxUIState
{
	override function create()
	{
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new FadeTransition(0.7, true));

		FlxTransitionableState.skipNextTransOut = false;

		Controls.onActionPressed.add(onActionPressed);
		Controls.onActionReleased.add(onActionReleased);
		super.create();
	}

	override function destroy()
	{
		Controls.onActionPressed.remove(onActionPressed);
		Controls.onActionReleased.remove(onActionReleased);
		super.destroy();
	}

	public static function switchState(nextState:FlxState)
	{
		var curState:Dynamic = FlxG.state;
		var leState:ScriptableState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new FadeTransition(0.6, false));
			if (nextState == FlxG.state)
			{
				FadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
			}
			else
			{
				FadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}
}

class ScriptableSubState extends FlxUISubState
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
		super.destroy();
	}

	function onActionPressed(action:String) {}

	function onActionReleased(action:String) {}
}

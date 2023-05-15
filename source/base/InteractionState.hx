package base;

import backend.Controls;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;
import transitions.FadeTransition;

// Holds the transitions, controls and language (soon)
class InteractionState extends FlxState
{
	override function create()
	{
		if (!FadeTransition.skipTransOut)
			openSubState(new FadeTransition(0.7, true));

		FadeTransition.skipTransOut = true;

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
		var curState:InteractionState = cast FlxG.state;
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
}

class InteractionSubState extends FlxSubState
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

	private function onActionPressed(action:String) {}

	private function onActionReleased(action:String) {}
}

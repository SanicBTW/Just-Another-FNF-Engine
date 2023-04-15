package base;

import base.system.Controls;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxSubState;

class ScriptableState extends FlxState
{
	public static var skipTransIn:Bool = false;
	public static var skipTransOut:Bool = false;

	override function create()
	{
		if (!skipTransOut)
			openSubState(new FadeTransition(0.7, true));

		skipTransOut = false;

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
		var curState:ScriptableState = cast FlxG.state;
		if (!skipTransIn)
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
		skipTransIn = false;
		FlxG.switchState(nextState);
	}

	public function onActionPressed(action:String) {}

	public function onActionReleased(action:String) {}
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
		super.destroy();
	}

	public function onActionPressed(action:String) {}

	public function onActionReleased(action:String) {}
}

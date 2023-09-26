package base;

import flixel.FlxG;
import flixel.FlxState;
import transitions.FadeTransition;

// In order to make transitions work, I need this so badly
class TransitionState extends FlxState implements ITransitionAPI
{
	override public function create()
	{
		if (!FadeTransition.skipTransOut)
			openSubState(new FadeTransition(0.7, true));

		FadeTransition.skipTransOut = false;

		super.create();
	}

	// Work with switchTo and add more transition support
	public static function switchState(nextState:FlxState)
	{
		var curState:FlxState = FlxG.state;
		if (!FadeTransition.skipTransIn)
		{
			curState.openSubState(new FadeTransition(0.6, false));
			FadeTransition.finishCallback = function()
			{
				if (nextState == curState)
					FlxG.resetState();
				else
					FlxG.switchState(nextState);
			}
			return;
		}

		FadeTransition.skipTransIn = false;
		FlxG.switchState(nextState);
	}
}

// -(dunno how to implement it actually) Transition API(Only has the Fade Transition cuz im too lazy)
// gonna leave it empty
interface ITransitionAPI {}

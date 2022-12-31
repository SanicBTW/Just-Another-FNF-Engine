package;

import base.Config;
import base.Cursor;
import base.ScriptableState;
import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;

class Init extends FlxState
{
	override function create()
	{
		super.create();

		FlxTransitionableState.skipNextTransIn = true;

		FlxG.save.bind("funkin_engine", "sanicbtw");
		Config.loadSettings();
		Paths.getGraphic("assets/images/cursorIdle.png");
		Paths.getGraphic("assets/images/cursorHover.png");
		Cursor.setCursor(IDLE);

		if (Config.firstTime)
			ScriptableState.switchState(new states.TestState());
	}
}

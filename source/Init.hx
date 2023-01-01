package;

import base.Config;
import base.Cursor;
import base.ScriptableState;
import extra.Prompt;
import flixel.FlxG;
import flixel.FlxSprite;

// shitiest init state lmao
class Init extends ScriptableState
{
	var shitPrompt:Prompt;
	var timeLeft:Int = 10;

	override function create()
	{
		#if !android
		Paths.getGraphic("assets/images/cursorIdle.png");
		Paths.getGraphic("assets/images/cursorHover.png");
		Cursor.currentState = IDLE;
		#end

		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuDefault"));
		bg.screenCenter();
		bg.antialiasing = Config.antialiasing;
		bg.alpha = 0.5;
		add(bg);

		shitPrompt = new Prompt("Hey there!", "This engine is in a really early state and might be unstable\nPlease report any issue you find",
			'You will be redirected in ${timeLeft}s');
		shitPrompt.screenCenter();
		add(shitPrompt);

		super.create();
	}

	var wait:Float = 0;

	// goofy ass timer lmao :sob:
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		wait += elapsed;
		if (wait >= 1)
		{
			wait = 0;
			timeLeft--;
		}

		if (timeLeft <= 0)
		{
			ScriptableState.switchState(new states.TestState());
		}

		if (FlxG.mouse.overlaps(shitPrompt))
			Cursor.currentState = HOVER;
		else
			Cursor.currentState = IDLE;

		shitPrompt.footer.text = 'You will be redirected in ${timeLeft}s';
	}
}

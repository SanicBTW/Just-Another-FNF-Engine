package;

import base.SaveData;
import base.ScriptableState;
import extra.Prompt;
import flixel.FlxG;
import flixel.FlxSprite;

// shitiest init state lmao
class Init extends ScriptableState
{
	var shitPrompt:Prompt;
	var timeLeft:Int = 5;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.alpha = 0.5;
		bg.setGraphicSize(FlxG.width, FlxG.height);
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
			ScriptableState.switchState(new states.TitleState());
		}

		shitPrompt.footer.text = 'You will be redirected in ${timeLeft}s';
	}
}

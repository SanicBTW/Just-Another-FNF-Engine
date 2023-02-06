package;

import base.SaveData;
import base.ScriptableState;
import base.ui.RoundedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import funkin.Prompt;
#if !fast_start
import base.pocketbase.Request;
import funkin.ChartLoader;
#end

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

		var shit:RoundedSprite = new RoundedSprite(0, 0, 250, 250, flixel.util.FlxColor.LIME);
		shit.screenCenter();
		add(shit);

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
			#if !fast_start
			ScriptableState.switchState(new states.MainState());
			#else
			Request.getFile("funkin", "yixzwztgjxfsmj1", "double_kill_hard_OfVOJgFZJQ.json", function(chart)
			{
				ChartLoader.netChart = chart;

				Request.getSound("funkin", "yixzwztgjxfsmj1", "inst_zUVNG1UAQT.ogg", function(sound)
				{
					ChartLoader.netInst = sound;
				});

				Request.getSound("funkin", "yixzwztgjxfsmj1", "voices_HrnHFmsQZ0.ogg", function(sound)
				{
					ChartLoader.netVoices = sound;
					ScriptableState.switchState(new states.PlayTest());
				});
			});
			#end
		}

		shitPrompt.footer.text = 'You will be redirected in ${timeLeft}s';
	}
}

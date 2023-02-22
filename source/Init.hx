package;

import base.SaveData;
import base.ScriptableState;
import base.system.Timer;
import base.ui.RoundedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.Prompt;
#if !fast_start
import base.pocketbase.Request;
import funkin.ChartLoader;
#end

class Init extends ScriptableState
{
	private var icon:FlxSprite;
	private var sineLoops:Int = 0;
	private var iconSine:Float;

	private var rounded:RoundedSprite;
	private var shitTimer:Timer;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite(0, 0, Paths.image("menuSDefault"));
		bg.screenCenter();
		bg.antialiasing = SaveData.antialiasing;
		bg.alpha = 0.5;
		bg.setGraphicSize(FlxG.width, FlxG.height);
		add(bg);

		var bbg:FlxSprite = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK, true);
		bbg.screenCenter();
		add(bbg);

		icon = new FlxSprite().loadGraphic(Paths.image("ui/hp"));
		icon.screenCenter();
		add(icon);

		rounded = new RoundedSprite(0, 0, FlxG.width - 150, FlxG.height - 150, FlxColor.GRAY);
		rounded.screenCenter();
		rounded.alpha = 0;
		rounded.scale.y = 0;
		add(rounded);

		shitTimer = new Timer(2, function()
		{
			icon.alpha = 0;
			icon = null;
			FlxTween.tween(bbg, {alpha: 0}, 1.2);
			FlxTween.tween(rounded.scale, {y: 1}, 0.9, {
				ease: FlxEase.quartInOut,
				startDelay: 1.2
			});
			FlxTween.tween(rounded, {alpha: 0.8}, 0.8, {
				ease: FlxEase.quartInOut,
				startDelay: 1.2,
				onComplete: function(_)
				{
					shitTimer.restart(5, function()
					{
						FlxTween.tween(rounded.scale, {y: 0}, 0.8, {
							ease: FlxEase.quartInOut,
							onComplete: function(_)
							{
								end();
							}
						});
					});
				}
			});
		}, function(elapsed:Float)
		{
			if (icon != null)
			{
				iconSine += 150 * elapsed;
				icon.alpha = 0.7 * Math.sin((Math.PI * iconSine) / 150);
			}
		});
		add(shitTimer);

		super.create();

		FlxTransitionableState.skipNextTransIn = false;
	}

	override function update(elapsed:Float)
	{
		/*
			if (icon == null && shitPrompt.alpha == 1)
			{
				shitPrompt.footer.text = 'You will be redirected in ${shitTimer.timeLeft}s';
		}*/

		super.update(elapsed);
	}

	function end()
	{
		#if !fast_start
		ScriptableState.switchState(new states.Fuckstat());
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
}

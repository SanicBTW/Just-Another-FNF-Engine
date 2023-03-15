package;

import base.ScriptableState;
import base.system.Timer;
import base.ui.Fonts;
import base.ui.RoundedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxBitmapText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import states.RewriteMenu;
#if fast_start
import base.pocketbase.Request;
import funkin.ChartLoader;
#end

class Init extends ScriptableState
{
	private var icon:FlxSprite;
	private var sineLoops:Int = 0;
	private var iconSine:Float;
	private var shitText:FlxBitmapText;

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

		shitText = new FlxBitmapText(Fonts.VCR());
		shitText.text = 'The engine is in beta state and might be unstable\nPlease report any issue you find\n\n\n\n\n\n\n\n\n\n\n\n\nYou will be redirected in 5s';
		shitText.alpha = 0;
		shitText.fieldWidth = Std.int(rounded.width);
		shitText.antialiasing = SaveData.antialiasing;
		shitText.setGraphicSize(Std.int(shitText.width * 0.5));
		shitText.centerOffsets();
		shitText.updateHitbox();
		shitText.setPosition(rounded.x + 10, rounded.y + 10);
		add(shitText);

		shitTimer = new Timer(2, function()
		{
			icon.alpha = 0;
			icon = null;
			FlxTween.tween(bbg, {alpha: 0}, 1.2);
			FlxTween.tween(rounded.scale, {y: 1}, 0.9, {
				ease: FlxEase.quartInOut,
				startDelay: 1.2
			});
			FlxTween.tween(shitText, {alpha: 1}, 0.9, {
				ease: FlxEase.quartInOut,
				startDelay: 1.7
			});
			FlxTween.tween(rounded, {alpha: 0.8}, 0.8, {
				ease: FlxEase.quartInOut,
				startDelay: 1.2,
				onComplete: function(_)
				{
					shitTimer.restart(5, function()
					{
						FlxTween.tween(shitText, {alpha: 0}, 0.5, {
							ease: FlxEase.quartInOut
						});
						FlxTween.tween(rounded.scale, {y: 0}, 0.8, {
							startDelay: 0.5,
							ease: FlxEase.quartInOut,
							onComplete: function(_)
							{
								ScriptableState.switchState(new RewriteMenu());
							}
						});
					}, function(elapsed:Float)
					{
						shitText.text = 'The engine is in beta state and might be unstable\nPlease report any issue you find\n\n\n\n\n\n\n\n\n\n\n\n\nYou will be redirected in ${shitTimer.timeLeft}s';
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

		ScriptableState.skipTransIn = false;
	}
}

package funkin.ui;

import base.Conductor;
import base.SaveData;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class JudgementPopUp extends FlxSpriteGroup
{
	private var comboSprite:FlxSprite;
	private var judgementSprite:FlxSprite;

	private var comboTwnScale:FlxTween;

	private var judgementTwnScale:FlxTween;

	public function new(X:Float, Y:Float)
	{
		super(X, Y);

		antialiasing = SaveData.antialiasing;

		// precache stuff
		comboSprite = new FlxSprite().loadGraphic(Paths.image('combo'), true, 100, 140);
		comboSprite.alpha = 0;
		comboSprite.screenCenter();
		comboSprite.antialiasing = antialiasing;
		comboSprite.setGraphicSize(Std.int(comboSprite.width * 0.5));
		comboSprite.updateHitbox();
		add(comboSprite);

		judgementSprite = new FlxSprite().loadGraphic(Paths.image('judgements'), true, 500, 163);
		judgementSprite.alpha = 0;
		judgementSprite.screenCenter();
		judgementSprite.antialiasing = antialiasing;
		judgementSprite.setGraphicSize(Std.int(judgementSprite.width * 0.7));
		judgementSprite.updateHitbox();
		add(judgementSprite);

		updateHitbox();
	}

	public function showCombo(number:String, marv:Bool, scoreInt:Int)
	{
		if (comboSprite.alpha == 0)
			comboSprite.alpha = 1;

		if (comboTwnScale != null)
			comboTwnScale.cancel();

		if (comboSprite.animation.exists('base'))
			comboSprite.animation.remove('base');
		comboSprite.animation.add('base', [(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!marv ? 0 : 11)], 0, false);
		comboSprite.animation.play('base');
		comboSprite.scale.set(0.75, 0.75);

		comboTwnScale = FlxTween.tween(comboSprite, {"scale.x": 0.5, "scale.y": 0.5}, 0.1, {
			onComplete: function(_)
			{
				comboTwnScale = null;
			},
			startDelay: Conductor.crochet * 0.00125
		});
	}

	public function showJudgement(judgement:String, marv:Bool, timing:String)
	{
		if (judgementSprite.alpha == 0)
			judgementSprite.alpha = 1;

		if (judgementTwnScale != null)
			judgementTwnScale.cancel();

		if (judgementSprite.animation.exists('base'))
			judgementSprite.animation.remove('base');
		judgementSprite.animation.add('base', [
			Std.int((Timings.getJudgementIndex(judgement) * 2) + (marv ? 0 : 2) + (timing == "late" ? 1 : 0))
		], 24, false);
		judgementSprite.animation.play('base');

		judgementSprite.scale.set(0.5, 0.5);
		judgementTwnScale = FlxTween.tween(judgementSprite, {"scale.x": 0, "scale.y": 0, alpha: 0}, 0.1, {
			onComplete: function(_)
			{
				judgementTwnScale = null;
			},
			startDelay: Conductor.crochet * 0.00125
		});
	}
}

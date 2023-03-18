package funkin.ui;

import base.ui.Fonts;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import funkin.Timings;
import openfl.text.TextFormatAlign;

class JudgementCounter extends FlxSpriteGroup
{
	private var trackJudgement:String;

	private var counterBG:FlxSprite;
	private var counterText:FlxBitmapText;

	public function new(X:Float, Y:Float, judgement:String)
	{
		super(X, Y);

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();
		setGraphicSize(60, 60);
		updateHitbox();

		var judgement:Judgement = Timings.getJudgementByName(judgement);
		trackJudgement = judgement.track;

		counterBG = new FlxSprite(0, 0).loadGraphic(Paths.image("judgementCounter"));
		counterBG.color = judgement.color;
		counterBG.setGraphicSize(60, 60);
		counterBG.antialiasing = antialiasing; // dawg wtf
		counterBG.scrollFactor.set();
		add(counterBG);

		counterText = new FlxBitmapText(Fonts.Funkin());
		Fonts.setProperties(counterText, false, 0.38);
		counterText.alignment = CENTER;
		counterText.fieldWidth = Std.int(counterBG.width);
		counterText.text = judgement.shortName;
		counterText.color = FlxColor.BLACK;
		// I hate manually setting the positions
		// 372.5, -25 -> 0.45 (Needs to be adjusted)
		// 385, -15 -> 0.4 (Perfectly centered, over 200 size issue)
		// 398, -14 -> 0.38 (Perfectly centered, perfect size apparently)
		counterText.setPosition(398, -14);
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		if (Reflect.field(Timings, trackJudgement) > 0)
			counterText.text = '${Reflect.field(Timings, trackJudgement)}';

		super.update(elapsed);
	}
}

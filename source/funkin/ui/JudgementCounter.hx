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
		Fonts.setProperties(counterText, false, 0.5);
		counterText.alignment = CENTER;
		counterText.fieldWidth = Std.int(counterBG.width);
		counterText.color = FlxColor.BLACK;
		counterText.text = judgement.shortName;
		counterText.setPosition(X, Y);
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		if (Reflect.field(Timings, trackJudgement) > 0)
			counterText.text = '${Reflect.field(Timings, trackJudgement)}';

		super.update(elapsed);
	}
}

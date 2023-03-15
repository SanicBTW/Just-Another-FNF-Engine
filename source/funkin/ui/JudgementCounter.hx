package funkin.ui;

import base.ui.TextComponent;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.Timings;
import openfl.text.TextFormatAlign;

class JudgementCounter extends FlxSpriteGroup
{
	private var trackJudgement:String;

	private var counterBG:FlxSprite;
	private var counterText:TextComponent;
	private var counterTxtSize:Int = 24;

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

		var positions:Array<Float> = [
			(-(counterBG.width / 2) + (counterBG.width / 2)),
			(counterBG.height / 2) - (counterTxtSize - 7)
		];
		counterText = new TextComponent(positions[0], positions[1], counterBG.width, judgement.shortName, counterTxtSize, "funkin.otf");
		counterText.color = FlxColor.BLACK;
		counterText.alignment = CENTER;
		counterText.scrollFactor.set();
		counterText.autoSize = false;
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		if (Reflect.field(Timings, trackJudgement) > 0)
			counterText.text = '${Reflect.field(Timings, trackJudgement)}';

		super.update(elapsed);
	}
}

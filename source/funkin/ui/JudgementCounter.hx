package funkin.ui;

import base.SaveData;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.Timings;
import openfl.text.TextFormatAlign;
#if use_flx_text
import flixel.text.FlxText;
#else
import base.ui.TextComponent;
#end

class JudgementCounter extends FlxSpriteGroup
{
	private var judgementIdx:Int;

	private var counterBG:FlxSprite;
	#if use_flx_text
	private var counterText:FlxText;
	#else
	private var counterText:TextComponent;
	#end
	private var counterTxtSize:Int = 24;

	public function new(X:Float, Y:Float, judgement:String)
	{
		super(X, Y);

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();
		judgementIdx = Timings.getJudgementIndex(judgement);
		setGraphicSize(60, 60);
		updateHitbox();

		counterBG = new FlxSprite(0, 0).loadGraphic(Paths.image("judgementCounter"));
		counterBG.color = Timings.Judgements[judgementIdx].Color;
		counterBG.setGraphicSize(60, 60);
		counterBG.antialiasing = antialiasing; // dawg wtf
		counterBG.scrollFactor.set();
		add(counterBG);

		var positions:Array<Float> = [
			(-(counterBG.width / 2) + (counterBG.width / 2)),
			(counterBG.height / 2) - (counterTxtSize - 7)
		];
		#if use_flx_text
		counterText = new FlxText(positions[0], positions[1], counterBG.width, judgements.get(judgement)[1], counterTxtSize);
		counterText.setFormat(Paths.font("funkin.otf"), counterTxtSize, FlxColor.BLACK);
		#else
		counterText = new TextComponent(positions[0], positions[1], counterBG.width, Timings.Judgements[judgementIdx].Short, counterTxtSize, "funkin.otf");
		counterText.color = FlxColor.BLACK;
		counterText.alignment = CENTER;
		#end
		counterText.scrollFactor.set();
		counterText.autoSize = false;
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		if (Timings.Judgements[judgementIdx].Combo > 0)
			counterText.text = '${Timings.Judgements[judgementIdx].Combo}';

		super.update(elapsed);
	}
}

package funkin.ui;

import base.Alphabet;
import base.SaveData;
import base.ui.TextComponent;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.Ratings;

// fix for non html targets
class JudgementCounter extends FlxSpriteGroup
{
	// var name, counter name, color
	public static var judgements:Map<String, Array<Dynamic>> = [
		"marvelous" => ["marvs", "MV", FlxColor.fromRGB(255, 255, 153)],
		"sick" => ["sicks", "SK", FlxColor.fromRGB(255, 255, 51)],
		"good" => ["goods", "GD", FlxColor.fromRGB(30, 144, 255)],
		"bad" => ["bads", "BD", FlxColor.fromRGB(148, 0, 211)],
		"shit" => ["shits", "ST", FlxColor.fromRGB(178, 34, 34)],
		"miss" => ["misses", "MS", FlxColor.fromRGB(204, 66, 66)]
	];

	private var judgement:String;
	private var judgementVar:String;

	private var counterBG:FlxSprite;
	/*private var counterText:TextComponent;*/
	private var counterText:Alphabet;

	private var counterTxtSize:Float = 0.5;

	public function new(x:Float, y:Float, judgement:String)
	{
		super(x, y);

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();
		this.judgement = judgement;
		judgementVar = judgements.get(judgement)[0];

		counterBG = new FlxSprite().loadGraphic(Paths.image("judgementCounter"));
		counterBG.color = judgements.get(judgement)[2];
		counterBG.setGraphicSize(55, 55);
		counterBG.antialiasing = antialiasing; // dawg wtf
		add(counterBG);

		counterText = new Alphabet((-(counterBG.width / 2) + (counterBG.width / 2)), (counterBG.height / 2) - (counterTxtSize - 7),
			judgements.get(judgement)[1], true, false, 0.05, counterTxtSize);
		add(counterText);
		/*
			counterText = new TextComponent((counterBG.width + counterBG.x) / 2, (counterBG.height + counterBG.y) / 2, counterBG.width,
				judgements.get(judgement)[1], counterTxtSize, "funkin.otf");
			(cast(openfl.Lib.current.getChildAt(0), Main)).addChild(counterText); */
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Reflect.field(Ratings, judgementVar) > 0)
			counterText.changeText('${Reflect.field(Ratings, judgementVar)}');
		// counterText.text = '${Reflect.field(Ratings, judgementVar)}';
	}
}

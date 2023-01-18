package funkin.ui;

import base.SaveData;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.Ratings;

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
	private var counterText:FlxText;

	private var counterTxtSize:Int = 16;

	public function new(x:Float, y:Float, judgement:String)
	{
		super(x, y);

		antialiasing = SaveData.antialiasing;
		scrollFactor.set();
		this.judgement = judgement;
		judgementVar = judgements.get(judgement)[0];

		counterBG = new FlxSprite().loadGraphic(Paths.image("judgementCounter"));
		counterBG.color = judgements.get(judgement)[2];
		add(counterBG);

		counterText = new FlxText((-(counterBG.width / 2) + (counterBG.width / 2)) + 2, (counterBG.height / 2) - (counterTxtSize - 7), counterBG.width,
			judgements.get(judgement)[1], counterTxtSize);
		counterText.alignment = CENTER;
		counterText.autoSize = false;
		counterText.color = FlxColor.BLACK;
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Reflect.field(Ratings, judgementVar) > 0)
			counterText.text = '${Reflect.field(Ratings, judgementVar)}';
	}
}

package funkin.ui;

import base.SaveData;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import funkin.Ratings;
import openfl.text.TextFormatAlign;
#if use_flx_text
import flixel.text.FlxText;
#else
import base.ui.TextComponent;
#end

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

	private var judgementVar:String;

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
		judgementVar = judgements.get(judgement)[0];
		setGraphicSize(60, 60);
		updateHitbox();

		counterBG = new FlxSprite(0, 0).loadGraphic(Paths.image("judgementCounter"));
		counterBG.color = judgements.get(judgement)[2];
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
		counterText = new TextComponent(positions[0], positions[1], counterBG.width, judgements.get(judgement)[1], counterTxtSize, "funkin.otf");
		counterText.color = FlxColor.BLACK;
		counterText.alignment = CENTER;
		#end
		counterText.scrollFactor.set();
		counterText.autoSize = false;
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (Reflect.field(Ratings, judgementVar) > 0)
			counterText.text = '${Reflect.field(Ratings, judgementVar)}';
	}
}

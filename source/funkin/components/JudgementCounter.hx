package funkin.components;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class JudgementCounter extends FlxSpriteGroup
{
	private var track:Judgement;

	private var counterBG:FlxSprite;
	private var counterText:FlxText;

	public function new(X:Float, Y:Float, judgement:Judgement)
	{
		super(X, Y);

		track = judgement;

		counterBG = new FlxSprite(0, 0).loadGraphic(Paths.image("ui/judgementCounter"));
		counterBG.color = judgement.color;
		counterBG.setGraphicSize(60, 60);
		updateHitbox();
		add(counterBG);

		counterText = new FlxText(0, 0, counterBG.width, judgement.shortName, 22);
		counterText.autoSize = false;
		counterText.font = Paths.font('funkin.otf');
		counterText.alignment = CENTER;
		counterText.color = FlxColor.BLACK;
		counterText.setPosition((counterBG.width - counterText.width) / 2, (counterBG.height - counterText.height) / 2);
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		if (track.counter > 0)
			counterText.text = '${track.counter}';
		else if (track.counter < 0 && counterText.text != track.shortName)
			counterText.text = track.shortName;

		super.update(elapsed);
	}
}

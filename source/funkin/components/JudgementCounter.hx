package funkin.components;

// I'm actually gonna have to rewrite this bruh
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.Timings;
import openfl.text.TextFormatAlign;

class JudgementCounter extends FlxSpriteGroup
{
	private var trackJudgement:String;

	private var counterBG:FlxSprite;
	private var counterText:FlxText;

	public function new(X:Float, Y:Float, judgement:String)
	{
		super(X, Y);

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

		counterText = new FlxText(0, 0, counterBG.width, judgement.shortName, 18);
		counterText.font = Paths.font('funkin.otf');
		counterText.alignment = CENTER;
		counterText.color = FlxColor.BLACK;
		counterText.setPosition((counterBG.width - counterText.width) / 2, (counterBG.height - counterText.height) / 2);
		add(counterText);
	}

	override public function update(elapsed:Float)
	{
		if (Reflect.field(Timings, trackJudgement) > 0)
			counterText.text = '${Reflect.field(Timings, trackJudgement)}';

		super.update(elapsed);
	}
}

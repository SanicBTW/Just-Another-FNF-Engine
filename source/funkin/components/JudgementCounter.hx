package funkin.components;

// I'm actually gonna have to rewrite this bruh - might do
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.Timings;

class JudgementCounter extends FlxSpriteGroup
{
	private var trackJudgement:String;
	private var defaultText:String;

	private var counterBG:FlxSprite;
	private var counterText:FlxText;

	public function new(X:Float, Y:Float, judgement:Judgement)
	{
		super(X, Y);

		defaultText = judgement.shortName;
		trackJudgement = judgement.track;

		counterBG = new FlxSprite(0, 0).loadGraphic(Paths.image("ui/judgementCounter"));
		counterBG.color = judgement.color;
		counterBG.setGraphicSize(60, 60);
		updateHitbox();
		add(counterBG);

		counterText = new FlxText(0, 0, counterBG.width, defaultText, 22);
		counterText.autoSize = false;
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
		else if (Reflect.field(Timings, trackJudgement) < 0 && counterText.text != defaultText)
			counterText.text = defaultText;

		super.update(elapsed);
	}
}

package funkin.ui;

#if use_flx_text
import flixel.text.FlxText;
#else
import base.ui.TextComponent;
#end
import base.Conductor;
import base.ui.Bar;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import funkin.ui.JudgementCounter;

// more components are expected to be added and moved to their respective files
class UI extends FlxSpriteGroup
{
	#if use_flx_text
	private var accuracyText:FlxText;
	#else
	private var accuracyText:TextComponent;
	#end

	private var scoreText:TextComponent;
	private var rankText:TextComponent;

	private var timeBar:Bar;

	public var popUp:JudgementPopUp;

	public function new()
	{
		super();

		#if use_flx_text
		accuracyText = new FlxText(30, (FlxG.height / 2), 0, "Accuracy 0%", 24);
		accuracyText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		accuracyText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		#else
		accuracyText = new TextComponent(30, (FlxG.height / 2), 0, 'Accuracy 0%', 24);
		accuracyText.fieldWidth *= 1.5;
		accuracyText.borderColor = FlxColor.BLACK;
		accuracyText.borderSize = 1.25;
		#end
		accuracyText.scrollFactor.set();
		add(accuracyText);

		scoreText = new TextComponent(30, (accuracyText.y + accuracyText.height) - 5, 0, "Score 000000", 24);
		scoreText.borderColor = FlxColor.BLACK;
		scoreText.borderSize = 1.25;
		scoreText.scrollFactor.set();
		add(scoreText);

		rankText = new TextComponent(30, (accuracyText.y - accuracyText.height) + 5, 0, "Rank N/A", 24);
		rankText.borderColor = FlxColor.BLACK;
		rankText.borderSize = 1.25;
		rankText.scrollFactor.set();
		add(rankText);

		timeBar = new Bar(0, 0, FlxG.width, 10, FlxColor.WHITE, FlxColor.fromRGB(30, 144, 255));
		timeBar.screenCenter();
		timeBar.y = FlxG.height - 10;
		timeBar.screenCenter(X);
		add(timeBar);

		var curY:Float = (FlxG.height / 2) + 150;
		for (i in 0...Timings.Judgements.length)
		{
			var counter:JudgementCounter = new JudgementCounter(FlxG.width - 65, curY, Timings.Judgements[i].Name);
			add(counter);
			curY -= 65;
		}

		popUp = new JudgementPopUp(0, 0);
		add(popUp);
	}

	override public function update(elapsed:Float)
	{
		timeBar.value = (Conductor.songPosition / Conductor.boundSong.audioLength);
		super.update(elapsed);
	}

	public function updateText()
	{
		var fcDisplay:String = (Timings.CurFC != null ? '[${Timings.CurFC}]' : '');
		accuracyText.text = 'Accuracy ${Timings.returnAccuracy()} ${fcDisplay}';
		scoreText.text = 'Score ${Timings.Score}';
		rankText.text = 'Rank ${Timings.CurRating}';
	}
}

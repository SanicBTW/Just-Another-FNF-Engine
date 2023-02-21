package funkin.ui;

import base.Conductor;
import base.system.Fonts;
import base.ui.Bar;
import flixel.FlxG;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.ui.JudgementCounter;
#if use_flx_text
import flixel.text.FlxText;
#else
import base.ui.TextComponent;
#end

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

	// private var rankText:FlxBitmapText;
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

		/*
			rankText = new FlxBitmapText(Fonts.VCR());
			rankText.setPosition(30, (accuracyText.y - accuracyText.height) + 5);
			rankText.text = "Rank N/A";
			rankText.setGraphicSize(Std.int(rankText.width * 0.4));
			rankText.updateHitbox();
			rankText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
			rankText.scrollFactor.set();
			add(rankText); */
		rankText = new TextComponent(30, (accuracyText.y - accuracyText.height) + 5, 0, "Rank N/A | [Clear] ", 24);
		rankText.borderColor = FlxColor.BLACK;
		rankText.borderSize = 1.25;
		rankText.scrollFactor.set();
		add(rankText);

		timeBar = new Bar(0, 0, FlxG.width, 10, FlxColor.WHITE, FlxColor.fromRGB(30, 144, 255));
		timeBar.screenCenter();
		timeBar.y = FlxG.height - 10;
		timeBar.screenCenter(X);
		add(timeBar);

		var judgementsArray:Array<String> = [];
		for (idx => judge in Timings.Judgements)
			judgementsArray.insert(idx, judge.Name);
		judgementsArray.sort(sortJudgements);

		var curY:Float = (FlxG.height / 2) + 150;
		for (i in 0...judgementsArray.length)
		{
			var counter:JudgementCounter = new JudgementCounter(FlxG.width - 65, curY, judgementsArray[i]);
			add(counter);
			curY -= 65;
		}

		popUp = new JudgementPopUp(0, 0);
		add(popUp);
	}

	private function sortJudgements(Obj1:String, Obj2:String)
	{
		return FlxSort.byValues(FlxSort.DESCENDING, Timings.getJudgementIndex(Obj1), Timings.getJudgementIndex(Obj2));
	}

	override public function update(elapsed:Float)
	{
		timeBar.value = (Conductor.songPosition / Conductor.boundSong.audioLength);
		super.update(elapsed);
	}

	public function updateText()
	{
		var fcDisplay:String = (Timings.CurFC != null ? ' | [${Timings.CurFC}]' : '');
		accuracyText.text = 'Accuracy ${Timings.returnAccuracy()}';
		scoreText.text = 'Score ${Timings.Score}';
		rankText.text = 'Rank ${Timings.CurRating}${fcDisplay}';
	}
}

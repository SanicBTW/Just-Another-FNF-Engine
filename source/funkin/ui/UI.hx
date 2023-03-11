package funkin.ui;

import base.system.Conductor;
import base.ui.Bar;
import base.ui.Fonts;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxBitmapText;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.ui.JudgementCounter;

class UI extends FlxSpriteGroup
{
	private var accuracyText:FlxBitmapText;
	private var scoreText:FlxBitmapText;
	private var rankText:FlxBitmapText;
	private var timeBar:Bar;

	public function new()
	{
		super();

		accuracyText = new FlxBitmapText(Fonts.VCR());
		setTextProps(accuracyText);
		accuracyText.setPosition(30, (FlxG.height / 2));
		accuracyText.text = "Accuracy 0%";
		add(accuracyText);

		scoreText = new FlxBitmapText(Fonts.VCR());
		setTextProps(scoreText);
		scoreText.setPosition(30, ((accuracyText.y + accuracyText.height) - (accuracyText.height / 2)));
		scoreText.text = "Score 0 | Combo 0";
		add(scoreText);

		rankText = new FlxBitmapText(Fonts.VCR());
		setTextProps(rankText);
		rankText.setPosition(30, ((accuracyText.y - accuracyText.height) + (accuracyText.height / 2)));
		rankText.text = "Rank N/A";
		add(rankText);

		timeBar = new Bar(0, 0, FlxG.width - 50, 10, FlxColor.WHITE, FlxColor.fromRGB(30, 144, 255));
		timeBar.screenCenter();
		timeBar.y = FlxG.height - 20;
		timeBar.screenCenter(X);
		add(timeBar);

		var judgementsArray:Array<String> = [];
		for (idx => judge in Timings.judgements)
			judgementsArray.insert(idx, judge.name);
		judgementsArray.sort(sortJudgements);

		var curY:Float = (FlxG.height / 2) + 150;
		for (i in 0...judgementsArray.length)
		{
			var counter:JudgementCounter = new JudgementCounter(FlxG.width - 65, curY, judgementsArray[i]);
			add(counter);
			curY -= 65;
		}
	}

	private function sortJudgements(Obj1:String, Obj2:String)
	{
		return FlxSort.byValues(FlxSort.DESCENDING, Timings.getJudgementIndex(Obj1), Timings.getJudgementIndex(Obj2));
	}

	private function setTextProps(text:FlxBitmapText)
	{
		text.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.25);
		text.scrollFactor.set();
		text.autoSize = false;
		text.alignment = LEFT;
		text.fieldWidth = FlxG.width;
		text.antialiasing = SaveData.antialiasing;
		text.setGraphicSize(Std.int(text.width * 0.35));
		text.centerOrigin();
		text.updateHitbox();
	}

	override public function update(elapsed:Float)
	{
		timeBar.value = (Conductor.songPosition / Conductor.boundSong.audioLength);
		super.update(elapsed);
	}

	public function updateText()
	{
		var fcDisplay:String = (Timings.ratingFC != null ? ' | [${Timings.ratingFC}]' : '');
		accuracyText.text = 'Accuracy ${Timings.getAccuracy()}';
		scoreText.text = 'Score ${Timings.score} | Combo ${Timings.combo}';
		rankText.text = 'Rank ${Timings.ratingName}${fcDisplay}';
	}
}

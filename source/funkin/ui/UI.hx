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

	public function new()
	{
		super();

		accuracyText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(accuracyText);
		accuracyText.setPosition(30, SaveData.downScroll ? (FlxG.height / 2) - (FlxG.height / 4) : (FlxG.height / 2) + (FlxG.height / 4));
		accuracyText.text = "Accuracy 0%";
		add(accuracyText);

		scoreText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(scoreText);
		scoreText.setPosition(30, ((accuracyText.y + accuracyText.height) - (accuracyText.height / 2)));
		scoreText.text = "Score 0";
		add(scoreText);

		rankText = new FlxBitmapText(Fonts.VCR());
		Fonts.setProperties(rankText);
		rankText.setPosition(30, ((accuracyText.y - accuracyText.height) + (accuracyText.height / 2)));
		rankText.text = "Rank N/A";
		add(rankText);

		var timeTracker:TimeTracker = new TimeTracker(0, SaveData.downScroll ? (FlxG.height - 45) : 20);
		add(timeTracker);

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

	public function updateText()
	{
		var fcDisplay:String = (Timings.ratingFC != null ? ' | [${Timings.ratingFC}]' : '');
		accuracyText.text = 'Accuracy ${Timings.getAccuracy()}';
		scoreText.text = 'Score ${Timings.score}';
		rankText.text = 'Rank ${Timings.ratingName}${fcDisplay}';
	}
}

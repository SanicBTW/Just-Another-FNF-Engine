package funkin.ui;

import base.Conductor;
import base.SaveData;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.Ratings;
import funkin.ui.JudgementCounter;
import states.PlayTest;

// more components are expected to be added and moved to their respective files
class UI extends FlxSpriteGroup
{
	private var accuracyText:FlxText;
	private var debugText:FlxText;

	public function new()
	{
		super();

		accuracyText = new FlxText(30, (FlxG.height / 2), 0, 'Accuracy 0%', 24);
		accuracyText.scrollFactor.set();
		accuracyText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		accuracyText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		add(accuracyText);

		debugText = new FlxText(30, (FlxG.height / 2) + (accuracyText.height), 0, 'BPM ${Conductor.bpm}\n', 24);
		debugText.scrollFactor.set();
		debugText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT);
		debugText.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		add(debugText);

		var judgementsArray:Array<String> = [];
		for (i in Ratings.judgements.keys())
			judgementsArray.insert(Ratings.judgements.get(i)[0], i);
		judgementsArray.sort(sortByJudgement);

		var curY:Float = (FlxG.height / 2) + 150;
		for (i in 0...judgementsArray.length)
		{
			var counter:JudgementCounter = new JudgementCounter(FlxG.width - 60, curY, judgementsArray[i]);
			add(counter);
			curY -= 60;
		}
	}

	private function sortByJudgement(Obj1:String, Obj2:String)
		return FlxSort.byValues(FlxSort.DESCENDING, Ratings.judgements.get(Obj1)[0], Ratings.judgements.get(Obj2)[0]);

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		accuracyText.text = 'Accuracy ${Math.floor(Ratings.accuracy * 100) / 100}%';
	}
}

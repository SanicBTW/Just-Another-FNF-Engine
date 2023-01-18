package funkin.ui;

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

	public function new()
	{
		super();

		accuracyText = new FlxText(30, (FlxG.height / 2), 0, 'Accuracy: 0%', 24);
		accuracyText.scrollFactor.set();
		accuracyText.setFormat(Paths.font("funkin.otf"), 24, FlxColor.WHITE, LEFT);
		accuracyText.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		add(accuracyText);

		// straight up from forever rewrite lol
		if (PlayTest.SONG != null)
		{
			var centerMark:FlxText = new FlxText(0, 0, 0, '- ${PlayTest.SONG.song.toUpperCase()} -\n', 24);
			centerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
			add(centerMark);
			centerMark.y = FlxG.height / 24;
			centerMark.screenCenter(X);
			centerMark.antialiasing = SaveData.antialiasing;
		}

		var judgementsArray:Array<String> = [];
		for (i in Ratings.judgements.keys())
			judgementsArray.insert(Ratings.judgements.get(i)[0], i);
		judgementsArray.sort(sortByJudgement);

		var curY:Float = (FlxG.height / 2) + 130;
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
		accuracyText.text = 'Accuracy: ${Math.floor(Ratings.accuracy * 100) / 100}%';
	}
}

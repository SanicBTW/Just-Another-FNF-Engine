package funkin.ui;

import base.SaveData;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.Ratings;
import states.PlayTest;

// more components are expected to be added and moved to their respective files
class UI extends FlxSpriteGroup
{
	private var accuracyText:FlxText;

	private var judgementsMap:Map<String, FlxText> = [];

	private var counterSize:Int = 20;

	public function new()
	{
		super();

		accuracyText = new FlxText(30, (FlxG.height / 2), 0, '', 24);
		accuracyText.scrollFactor.set();
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

		for (i in 0...judgementsArray.length)
		{
			var counter:FlxText = new FlxText(FlxG.width - 55, (FlxG.height / 2) - (counterSize * (judgementsArray.length / 2)) + (i * counterSize), 0,
				Ratings.counters.get(judgementsArray[i])[1], counterSize);
			counter.color = Ratings.counters.get(judgementsArray[i])[2];
			counter.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
			counter.scrollFactor.set();
			judgementsMap.set(judgementsArray[i], counter);
			add(counter);
		}
	}

	private function sortByJudgement(Obj1:String, Obj2:String)
		return FlxSort.byValues(FlxSort.ASCENDING, Ratings.judgements.get(Obj1)[0], Ratings.judgements.get(Obj2)[0]);

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		accuracyText.text = '${Math.floor(Ratings.accuracy * 100) / 100}%';

		for (i in judgementsMap.keys())
		{
			if (Reflect.field(Ratings, Ratings.counters.get(i)[0]) > 0)
			{
				judgementsMap.get(i).text = '${Reflect.field(Ratings, Ratings.counters.get(i)[0])}';
			}
		}
	}
}

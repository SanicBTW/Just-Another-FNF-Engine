package funkin;

import flixel.util.FlxColor;
import funkin.ui.JudgementCounter;

using StringTools;

class Ratings
{
	public static var msThreshold:Float = 0;
	private static var fakeAccuracy:Float;
	public static var accuracy:Float;
	public static var notesHit:Int = 0;

	public static var marvs:Int = 0;
	public static var sicks:Int = 0;
	public static var goods:Int = 0;
	public static var bads:Int = 0;
	public static var shits:Int = 0;
	public static var misses:Int = 0;

	// judgement weights from quaver's new system
	// pos, weight
	public static var judgements:Map<String, Array<Dynamic>> = [
		"marvelous" => [0, 100],
		"sick" => [1, 98.25],
		"good" => [2, 65],
		"bad" => [3, 25],
		"shit" => [4, -100],
		"miss" => [5, -50]
	];

	// timings from quaver's standard windows
	private static var timings:Array<Dynamic> = [
		[18, "marvelous"],
		[43, "sick"],
		[76, "good"],
		[106, "bad"],
		[127, "shit"],
		[165, "miss"]
	];

	public static function call()
	{
		marvs = 0;
		sicks = 0;
		goods = 0;
		bads = 0;
		shits = 0;
		misses = 0;

		fakeAccuracy = 0.001;
		accuracy = 0;

		var biggest:Float = 0;
		for (i in 0...timings.length)
			if (timings[i][0] > biggest)
				biggest = timings[i][0];
		msThreshold = biggest;

		notesHit = 0;
	}

	public static function judge(ms:Float)
	{
		for (i in 0...timings.length)
		{
			if (ms <= timings[Math.round(Math.min(i, timings.length - 1))][0])
			{
				var judgement:String = timings[Math.round(Math.min(i, timings.length - 1))][1];
				var judgeVar:String = JudgementCounter.judgements.get(judgement)[0];
				Reflect.setField(Ratings, judgeVar, Reflect.field(Ratings, judgeVar) + 1);
				return judgement;
			}
		}

		return 'miss';
	}

	public static function updateAccuracy(judgement:Int, ?isSustain:Bool = false, ?segmentCount:Int = 1)
	{
		if (!isSustain)
		{
			notesHit++;
			fakeAccuracy += (Math.max(0, judgement));
		}
		else
			fakeAccuracy += (Math.max(0, judgement) / segmentCount);

		accuracy = (fakeAccuracy / notesHit);
	}
}

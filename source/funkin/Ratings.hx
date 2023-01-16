package funkin;

using StringTools;

class Ratings
{
	public static var msThreshold:Float = 0;
	private static var fakeAccuracy:Float;
	public static var accuracy:Float;
	public static var notesHit:Int = 0;

	public static var judgements:Map<String, Array<Dynamic>> = [
		"marvellous" => [0, 100],
		"sick" => [1, 95],
		"good" => [2, 75],
		"bad" => [3, 25],
		"shit" => [4, -150],
		"miss" => [5, -175]
	];

	private static var timings:Array<Dynamic> = [
		[15, "marvellous"],
		[45, "sick"],
		[90, "good"],
		[135, "bad"],
		[157.5, "shit"],
		[180, "miss"]
	];

	public static function call()
	{
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
				return timings[Math.round(Math.min(i, timings.length - 1))][1];
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

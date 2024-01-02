package funkin;

import backend.Conductor;

class Timings
{
	// Judgements
	public static var misses(get, null):Int;

	@:noCompletion
	private static function get_misses():Int
		return judgements[judgements.length - 1].counter;

	// Combo & FC lowest
	public static var lowestRating:String = "sick";
	public static var maxCombo:Int = 0;
	public static var combo:Int = 0;

	// Player
	public static var health:Float = 1;
	public static var score:Int = 0;

	// Accuracy
	public static var totalHits:Int = 0;
	public static var notesAccuracy:Float = 0;
	public static var accuracy(get, never):Float;

	@:noCompletion
	private static function get_accuracy():Float
	{
		var acc:Float = switch (Settings.accuracyStyle)
		{
			case MS: (notesAccuracy / totalHits);
			case SCORE: (score / ((totalHits + misses) * judgements[0].score)) * 100;
		}
		return Math.min(100, Math.max(0, acc));
	}

	// HUD
	public static var ratingName:String = "N/A";
	public static var ratingFC:Null<String> = null;

	// Judgements metadata
	// All health values are half the prev (beginning 0.07)
	// Quaver judgements with the fixed diffs is kind of mean actually, really cool
	public static var judgements:Array<Judgement> = [];

	// I don't understand how to set the ratings lol
	public static final accuracyRatings:Map<String, Int> = [
		"Perfect!" => 100,
		"Sick!" => 90,
		"Good" => 80,
		"Meh" => 70,
		"Bad" => 60,
		"You Suck" => 58
	];

	public static function call()
	{
		ratingName = "N/A";
		ratingFC = null;

		lowestRating = "sick";
		maxCombo = 0;
		combo = 0;

		health = 1;
		score = 0;

		totalHits = 0;
		notesAccuracy = 0;

		for (judgement in judgements)
		{
			judgement.counter = 0;
		}
	}

	public static function judge(ms:Float, isSustain:Bool = false):String
	{
		for (i in 0...judgements.length)
		{
			var judgement:Judgement = judgements[Math.round(Math.min(i, judgements.length - 1))];
			if (judger(ms, judgement.timing))
			{
				// If is a sustain we only want to return the rating
				if (isSustain)
					return judgement.name;

				// Increase combo
				judgement.counter++;

				// Set the lowest rating
				if (lowestRating != judgement.name)
				{
					if (getJudgementIndex(lowestRating) < getJudgementIndex(judgement.name))
						lowestRating = judgement.name;
				}

				// Set more vars
				if (judgement.name == "miss" || judgement.name == "shit")
					combo = 0;
				else
				{
					combo++;
					totalHits++;
				}

				if (Settings.ratingStyle == ETTERNA)
					notesAccuracy += wife3(ms, Conductor.timeScale);
				else
					notesAccuracy += judgement.weight;

				score += judgement.score;

				if (health >= 2)
					health = 2;

				if (health <= 0)
					health = 0;

				health += judgement.health;

				// Set the max combo
				if (combo > maxCombo)
					maxCombo = combo;

				return judgement.name;
			}
		}

		return judgements[judgements.length - 1].name;
	}

	public static function getAccuracy():String
	{
		var retString:String = "0%";
		if (totalHits > 0)
		{
			retString = '${Math.floor(accuracy * 100) / 100}%';
			updateRank();
		}
		return retString;
	}

	public static function getJudgementIndex(searchJudgement:String)
	{
		for (judgement in judgements)
		{
			if (judgement.name == searchJudgement)
				return judgements.indexOf(judgement);
		}
		return 0;
	}

	public static function getJudgementByName(name:String)
	{
		for (judgement in judgements)
		{
			if (judgement.name == name)
				return judgement;
		}

		return null;
	}

	// Helper functions
	// Depending on the Rating Style, it will use another Judge, it can be more accurate or not
	private static function judger(ms:Float, timing:Float):Bool
	{
		return switch (Settings.ratingStyle)
		{
			// i fucking dont know what to do with etterna judger so ill just set it with kade since it will always judge based off the diff and add a custom weight
			case KADE | ETTERNA: Math.abs(ms) <= (timing * Conductor.timeScale);
			// basically 166 * (100 (sick) / 166) -> 166 * 0.27 -> 44,9
			case PSYCH: Math.abs(ms) <= (Conductor.safeZoneOffset * (timing / Conductor.safeZoneOffset));
		}
	}

	private static function updateRank()
	{
		// I didn't have a chance, had to copy the code from Forever lol
		var biggest:Int = 0;
		for (rating in accuracyRatings.keys())
		{
			if ((accuracyRatings.get(rating) <= accuracy) && (accuracyRatings.get(rating) >= biggest))
			{
				biggest = accuracyRatings.get(rating);
				ratingName = rating;
			}
		}

		ratingFC = "";
		if (getJudgementByName(lowestRating).fcStatus != null)
			ratingFC = getJudgementByName(lowestRating).fcStatus;
		else
			ratingFC = (misses > 0 && misses < 10) ? "SDCB" : null;
	}

	// ETTERNA - WIFE3 FROM https://github.com/SanicBTW/Kade-Engine-1.6.2/blob/master/source/EtternaFunctions.hx
	// When possible I will work more on this
	// erf constants
	private static var a1 = 0.254829592;
	private static var a2 = -0.284496736;
	private static var a3 = 1.421413741;
	private static var a4 = -1.453152027;
	private static var a5 = 1.061405429;
	private static var p = 0.3275911;

	private static function erf(x:Float):Float
	{
		// Save the sign of x
		var sign = 1;
		if (x < 0)
			sign = -1;
		x = Math.abs(x);

		// A&S formula 7.1.26
		var t = 1.0 / (1.0 + p * x);
		var y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);

		return sign * y;
	}

	private static function wife3(maxms:Float, ts:Float):Float
	{
		var max_points = 1.0;
		var miss_weight = -5.5;
		var ridic = 5 * ts;
		var max_boo_weight = 180 * ts;
		var ts_pow = 0.75;
		var zero = 65 * (Math.pow(ts, ts_pow));
		var power = 2.5;
		var dev = 22.7 * (Math.pow(ts, ts_pow));

		if (maxms <= ridic) // anything below this (judge scaled) threshold is counted as full pts
			return max_points;
		else if (maxms <= zero) // ma/pa region, exponential
			return max_points * erf((zero - maxms) / dev);
		else if (maxms <= max_boo_weight) // cb region, linear
			return (maxms - zero) * miss_weight / (max_boo_weight - zero);
		else
			return miss_weight;
	}
}

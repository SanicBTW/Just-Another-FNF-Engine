package funkin;

import backend.Conductor;
import flixel.util.FlxColor;

// I don't really know how to rewrite this one so I'm just gonna copy the old code lol

typedef Judgement =
{
	var name:String; // Judgement name
	var timing:Float; // MS to achieve the judgement
	var weight:Float; // The weight/accuracy of the judgement

	var fcStatus:Null<String>; // The FC rating aka SFC/FC
	var score:Int; // Given score by achieving the judgement
	var health:Float; // Amount of health given
	var shortName:String; // The initials? (what is displayed if there isn't any combo)
	var color:FlxColor; // The judgement color
	var track:String; // The "this" variable to track
}

enum RatingStyle
{
	PSYCH;
	KADE;
}

enum AccuracyStyle
{
	SCORE;
	MS;
}

class Timings
{
	// Judgements
	public static var marvs:Int = 0;
	public static var sicks:Int = 0;
	public static var goods:Int = 0;
	public static var bads:Int = 0;
	public static var shits:Int = 0;
	public static var misses:Int = 0;

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
	// DO AN OPTION TO CHANGE MS RATING STYLES
	// Kade MS Rating is based on timeScale, which is more mean and accurate most of the times
	// Pshcy MS Rating is based on the Conductor safeZoneOffset which is safeFrames (default:10) / 60 * 1000, its more permissive and maybe accurate
	public static final judgements:Array<Judgement> = [
		{
			name: 'sick',
			timing: Settings.sickTiming,
			weight: 100,
			fcStatus: 'SFC',
			health: 0.035,
			score: 350,
			shortName: "SK",
			color: FlxColor.fromRGB(255, 255, 51),
			track: "sicks"
		},
		{
			name: 'good',
			timing: Settings.goodTiming,
			weight: 75,
			fcStatus: 'GFC',
			health: 0.0175,
			score: 150,
			shortName: "GD",
			color: FlxColor.fromRGB(30, 144, 255),
			track: "goods"
		},
		{
			name: 'bad',
			timing: Settings.badTiming,
			weight: 50,
			fcStatus: 'FC',
			health: -0.00875,
			score: 50,
			shortName: "BD",
			color: FlxColor.fromRGB(148, 0, 211),
			track: "bads"
		},
		{
			name: 'shit',
			timing: Settings.shitTiming,
			weight: 25,
			fcStatus: null,
			health: -0.2,
			score: -50,
			shortName: 'ST',
			color: FlxColor.fromRGB(178, 34, 34),
			track: "shits"
		},
		{
			name: 'miss',
			timing: Settings.missTiming,
			weight: -100,
			fcStatus: null,
			health: -0.0475,
			score: -100,
			shortName: 'MS',
			color: FlxColor.fromRGB(204, 66, 66),
			track: "misses"
		}
	];

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

		marvs = 0;
		sicks = 0;
		goods = 0;
		bads = 0;
		shits = 0;
		misses = 0;
	}

	public static function judge(ms:Float, isSustain:Bool = false):String
	{
		for (i in 0...judgements.length)
		{
			var judgement:Judgement = judgements[Math.round(Math.min(i, judgements.length - 1))];
			if (ms <= judgement.timing * Conductor.timeScale)
			{
				// If is a sustain we only want to increase the notes accuracy and total hits
				if (isSustain)
				{
					notesAccuracy += judgement.weight;
					totalHits++;
					return judgement.name;
				}

				// Increase combo
				Reflect.setField(Timings, judgement.track, Reflect.field(Timings, judgement.track) + 1);

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

		// shits should count as misses too ig
		ratingFC = "";
		if (getJudgementByName(lowestRating).fcStatus != null)
			ratingFC = getJudgementByName(lowestRating).fcStatus;
		else
			ratingFC = ((misses > 0 || shits > 0) && (misses < 10 && shits < 10)) ? "SDCB" : null;
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
}

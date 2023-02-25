package funkin;

import flixel.util.FlxColor;
import haxe.ds.StringMap;

// File rewritten to fit newest Forever Engine Rewrite schema

typedef Judgement =
{
	var Name:String; // Judgement name
	var Timing:Float; // MS to achieve the judgement
	var Weight:Float; // The weight/accuracy of the judgement

	var FCRating:Null<String>; // The FC rating aka MFC/SFC/FC
	var Combo:Int; // The current judgement combo
	var Score:Int; // Given score by achieving the judgement
	var Health:Float; // Amount of health given
	var Short:String; // The initials? (what is displayed if there isn't any combo)
	var Color:FlxColor; // The judgement color
}

// Tried basing all of it on Quaver stuff lol - bruh think about better names or something dawg
class Timings
{
	// For note stuff
	public static var Threshold:Float = 200;

	// Combo stuff
	public static var HighestCombo:Int = 0;
	public static var CurrentCombo:Int = 0;

	// Player
	public static var Health:Float = 1;
	public static var Score:Int = 0;

	// Accuracy
	public static var TotalHits:Int = 0;
	public static var NotesAccuracy:Float = 0;
	public static var Accuracy(get, never):Float;

	private static function get_Accuracy():Float
		return NotesAccuracy / TotalHits;

	// Info
	public static var CurRating:String = "N/A";
	public static var HighestFC:Int = 0; // For fc shit
	public static var CurFC:Null<String> = null;

	// Setting judgements - long ass array bruh
	public static var Judgements:Array<Judgement> = [
		{
			Name: "marvelous",
			Timing: 18,
			Weight: 100,
			FCRating: 'MFC',
			Health: 1,
			Score: 450,
			Combo: 0,
			Short: "MV",
			Color: FlxColor.fromRGB(255, 255, 153)
		},
		{
			Name: 'sick',
			Timing: 43,
			Weight: 98.25,
			FCRating: 'SFC',
			Health: 0.75,
			Score: 350,
			Combo: 0,
			Short: "SK",
			Color: FlxColor.fromRGB(255, 255, 51)
		},
		{
			Name: 'good',
			Timing: 76,
			Weight: 65,
			FCRating: 'GFC',
			Health: 0.5,
			Score: 150,
			Combo: 0,
			Short: "GD",
			Color: FlxColor.fromRGB(30, 144, 255)
		},
		{
			Name: 'bad',
			Timing: 106,
			Weight: 25,
			FCRating: 'FC',
			Health: 0.2,
			Score: 50,
			Combo: 0,
			Short: "BD",
			Color: FlxColor.fromRGB(148, 0, 211)
		},
		{
			Name: 'shit',
			Timing: 127,
			Weight: -100,
			FCRating: null,
			Health: -0.5,
			Score: -50,
			Combo: 0,
			Short: 'ST',
			Color: FlxColor.fromRGB(178, 34, 34)
		},
		{
			Name: 'miss',
			Timing: 164,
			Weight: -100,
			FCRating: null,
			Health: -1,
			Score: -100,
			Combo: 0,
			Short: 'MS',
			Color: FlxColor.fromRGB(204, 66, 66)
		}
	];

	public static var scoreRating:Array<Dynamic> = [
		['X', 1],
		['SS', 1],
		['S', 0.98],
		['A', 0.94],
		['B', 0.89],
		['C', 0.79],
		['D', 0.69],
		['F', 0.60]
	];

	public static function call()
	{
		HighestCombo = 0;
		CurrentCombo = 0;
		HighestFC = 0;

		Health = 1;
		Score = 0;

		TotalHits = 0;
		NotesAccuracy = 0;

		// reset the combo stored in the object
		for (judgement in Judgements)
			judgement.Combo = 0;
	}

	public static function judge(ms:Float):Judgement
	{
		for (i in 0...Judgements.length)
		{
			if (ms <= Judgements[Math.round(Math.min(i, Judgements.length - 1))].Timing)
			{
				var judgement:Judgement = Judgements[Math.round(Math.min(i, Judgements.length - 1))];
				judgement.Combo += 1;
				return judgement;
			}
		}

		return Judgements[Judgements.length - 1];
	}

	public static function returnAccuracy():String
	{
		var returnString:String = "0%";
		if (TotalHits > 0)
			returnString = '${Math.floor(Accuracy * 100) / 100}%';
		updateRank();
		return returnString;
	}

	private static function updateRank()
	{
		trace(Accuracy);
		if (TotalHits < 0)
			CurRating = scoreRating[scoreRating.length - 1][0];
		else
		{
			for (i in 0...scoreRating.length - 1)
			{
				if (Accuracy < scoreRating[i][1])
				{
					CurRating = scoreRating[i][0];
					break;
				}
			}
		}

		if (Judgements[HighestFC].FCRating != null)
			CurFC = Judgements[HighestFC].FCRating;
		else
			CurFC = (Judgements[Judgements.length - 1].Combo < 10 ? "SDCB" : null);
	}

	// dawg :sob:
	public static function getJudgementIndex(searchJudgement:String):Int
	{
		for (judgement in Judgements)
		{
			if (judgement.Name == searchJudgement)
				return Judgements.indexOf(judgement);
		}
		return 0;
	}
}

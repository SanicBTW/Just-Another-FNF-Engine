package funkin;

import backend.Cache;
import backend.IO;
import backend.io.Path;
import flixel.util.FlxColor;
import haxe.xml.Access;

// Etterna was borrowed from Kade but you already know how Etterna works from there so yea
// Kade is based on timeScale, which is more mean and accurate most of the times
// Psych is based on the Conductor safeZoneOffset which is safeFrames (default:10) / 60 * 1000, its more permissive and maybe accurate
enum RatingStyle
{
	ETTERNA;
	PSYCH;
	KADE;
}

// Kade is always based off MS but you can select Score which is the default rating before Psych 0.4 I believe
enum AccuracyStyle
{
	SCORE;
	MS;
}

// Time Diff is the default one every engine (Conductor time - note time)
// Hitbox Diff however was implemented on this one (just for fun) and thought it was more accurate (Distance to the receptor screen pos from the receptor note pos)
// I dont really know if its actually hitbox or whatever to call it now but it just pretty much checks the note distance (position, not hitbox) to the receptor (position, not hitbox)
// Late conditions are also different for each one
enum DiffStyle
{
	TIME;
	HITBOX;
}

@:publicFields
class Judgement
{
	var name(default, null):String; // Judgement name
	var timing(default, null):Float; // Difference to achieve the judgement
	var weight(default, null):Float; // The weight/accuracy of the judgement

	var fcStatus(default, null):Null<String>; // The FC rating aka SFC/FC
	var score(default, null):Int; // Given score by achieving the judgement
	var health(default, null):Float; // Amount of health given

	var shortName:String; // The initials? (what is displayed if there isn't any combo)
	var color:FlxColor; // The judgement color

	@:noCompletion
	var counter:Int = 0; // DO NOT expose this variable to completion for good measure lol

	public function new() {}

	public function toString():String
		return '[ Judgement "${name}" | $timing $weight $fcStatus $score $health $shortName ${color.toWebString()} ]';

	// Based off https://github.com/SanicBTW/Just-Another-FNF-Engine/blob/221672cfcc8e77ab1db4b5a11e23b14e642425a2/source/base/system/Language.hx
	private static var xml:Access;

	// Static functions for populating data through the XML
	public static function populate()
	{
		var path:String = Path.join(IO.getFolderPath(DATA), "judgements.xml");
		if (!IO.exists(path))
			path = Paths.file('data/judgements.xml');

		try
		{
			xml ??= xml = new Access(Xml.parse(Cache.getText(path)));

			for (child in xml.elements)
			{
				var newJudgement:Judgement = new Judgement();

				newJudgement.name = child.att.name;

				// Required ones
				newJudgement.weight = Std.parseFloat(child.node.weight.innerData);
				newJudgement.health = Std.parseFloat(child.node.health.innerData);
				newJudgement.score = Std.parseInt(child.node.score.innerData);

				// Required for the UI
				newJudgement.shortName = child.node.health.innerData;
				if (child.node.color.att.format == "rgb")
				{
					var rgb:Array<String> = child.node.color.innerData.split(",");
					newJudgement.color = FlxColor.fromRGB(Std.parseInt(rgb[0]), Std.parseInt(rgb[1]), Std.parseInt(rgb[2]));
				}

				// Optionals
				newJudgement.fcStatus = (child.hasNode.fcStatus) ? child.node.fcStatus.innerData : null;
				newJudgement.timing = (child.hasNode.forceTiming) ? Std.parseInt(child.node.forceTiming.innerData) : Reflect.field(Settings,
					'${newJudgement.name}Timing');

				trace(newJudgement.toString());

				Timings.judgements.push(newJudgement);
			}
		}
		catch (ex)
		{
			trace('Failed to puplate XML $ex');
		}
	}
}

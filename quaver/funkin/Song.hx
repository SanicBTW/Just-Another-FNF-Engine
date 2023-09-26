package funkin;

import haxe.Json;

using StringTools;

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Null<Int>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var speed:Float;
	var needsVoices:Bool;
}

class Song
{
	public static function createFromRaw(rawInput:String):SwagSong
	{
		while (!rawInput.endsWith("}"))
		{
			rawInput = rawInput.substr(0, rawInput.length - 1);
		}

		return cast Json.parse(rawInput).song;
	}
}

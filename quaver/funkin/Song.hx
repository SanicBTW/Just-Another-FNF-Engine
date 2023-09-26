package funkin;

import haxe.Json;

using StringTools;

enum LineType
{
	HEADER;
	BODY;
}

typedef SectionLine =
{
	var type:LineType;
	var time:Float;
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Null<Int>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var bpm:Null<Float>;
	var changeBPM:Bool;

	// section info shit for section creation my bad
	var startTime:Float; // based on step crochets no funky elapsed shit sorry
	var endTime:Float;
	var lines:Array<SectionLine>;
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

		// Recalculate section timings based on the section bpm
		var swagShit:SwagSong = cast Json.parse(rawInput).song;
		var bpm:Float = swagShit.bpm;

		for (section in swagShit.notes)
		{
			var index:Int = swagShit.notes.indexOf(section);
			if (section.changeBPM)
				bpm = section.bpm;

			// 4 beats of the section * 4 default beats = 16 steps
			var steps:Int = (section.sectionBeats != null) ? (section.sectionBeats * 4) : section.lengthInSteps;
			// 16 steps / 4 default beats = 4 beats
			var beats:Int = (section.sectionBeats != null) ? section.sectionBeats : Math.floor((section.lengthInSteps / 4));

			var crochet:Float = (60 / bpm) * 1000;
			var stepCrochet:Float = (crochet / beats);

			// So the uhhhhh section must always need a header section including 4 body lines
			section.startTime = (index * stepCrochet);
			section.endTime = (section.startTime * steps);
			trace(bpm, section.startTime, section.endTime);
		}

		return swagShit;
	}
}

package funkin;

import haxe.Json;

using StringTools;

typedef SectionData =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Null<Int>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef SongData =
{
	var song:String;
	var notes:Array<SectionData>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var speed:Float;
	var sections:Null<Int>;
	var needsVoices:Bool;
	var player1:String;
	var player2:String;
	var player3:String;
	var gfVersion:String;
	var stage:String;
	var arrowSkin:String;
	var validScore:Bool;
}

class SongTools
{
	public static function onLoadJson(songJson:SongData)
	{
		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SectionData = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else
						i++;
				}
			}
		}

		if (songJson.sections == null)
		{
			songJson.sections = 0;

			for (sect in songJson.notes)
			{
				songJson.sections++;
			}
		}
	}

	public static function loadSong(rawInput:String):SongData
	{
		while (!rawInput.endsWith("}"))
		{
			rawInput = rawInput.substr(0, rawInput.length - 1);
		}

		var songJson:SongData = cast Json.parse(rawInput).song;
		songJson.validScore = true;
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseCharType(value:String):Int
	{
		var charType = 0;

		switch (value.toLowerCase())
		{
			default:
				charType = Std.parseInt(value);
				if (Math.isNaN(charType))
					charType = 0;
			case 'dad' | 'opponent' | '1':
				charType = 1;
			case 'gf' | 'girlfriend' | '2':
				charType = 2;
		}

		trace(charType);
		return charType;
	}
}

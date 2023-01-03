package base;

import haxe.Json;
import openfl.Assets;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var player3:String;
	var gfVersion:String;
	var stage:String;
	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var player3:String = 'gf'; // deprecated
	public var gfVersion:String = 'gf';
	public var stage:String;
	public var arrowSkin:String;
	public var splashSkin:String;

	private static function onLoadJson(songJson:SwagSong)
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
				var sec:SwagSection = songJson.notes[secNum];

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
	}

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	/*
		public static function loadFromJSON(song:String):SwagSong
		{
			var rawJson = Assets.getText(Paths.chart(song, "hard")).trim();

			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
			}

			var songJson:SwagSong = parseJSONshit(rawJson);
			onLoadJson(songJson);
			return songJson;
	}*/
	public static function loadFromRaw(rawInput:String):SwagSong
	{
		while (!rawInput.endsWith("}"))
		{
			rawInput = rawInput.substr(0, rawInput.length - 1);
		}

		var songJson:SwagSong = parseJSONshit(rawInput);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Section
{
	public var sectionNotes:Array<Dynamic> = [];
	public var lengthInSteps:Int = 16;
	public var mustHitSection:Bool = true;
	public var gfSection:Bool = false;
	public var bpm:Float = 0;
	public var changeBPM:Bool = false;
	public var altAnim:Bool = false;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}

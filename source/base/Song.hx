package base;

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

	public static function loadFromJSON(jsonInput:String, ?folder:String) {}

	public static function loadFromRaw(rawInput:String) {}
}

typedef SwagSection =
{
	var startTime:Float;
	var endTime:Float;
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Int;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

class Section
{
	public var startTime:Float = 0;
	public var endTime:Float = 0;
	public var sectionNotes:Array<Dynamic> = [];
	public var changeBPM:Bool = false;
	public var bpm:Float = 0;

	public var lengthInSteps:Int = 16;
	public var gfSection:Bool = false;
	public var mustHitSection:Bool = true;

	public function new(lengthInSteps:Int = 16)
	{
		this.lengthInSteps = lengthInSteps;
	}
}

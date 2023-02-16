package base.osu;

import funkin.notes.Note;

using StringTools;

// mix code from my 0.3.2h repo and osu!lazer code (?)
// has metadata included in here lol
class Beatmap
{
	public var Origin:String = "";

	public var Title:String = "";
	public var TitleUnicode:String = "";

	public var Artist:String = "";
	public var ArtistUnicode:String = "";

	public var PreviewTime:Int = -1;
	public var AudioFile:String = "";
	public var BackgroundFile:String = "";

	public var BPM:Float = 0;
	public var Notes:Array<Note> = [];
	public var Breaks:Array<BreakPeriod> = [];

	private var storedBeatmap:Array<String> = [];

	public function new(store:Array<String>)
	{
		this.storedBeatmap = store;
	}

	public function find(find:String):Int
		return (storedBeatmap[storedBeatmap.indexOf(find)] != null ? storedBeatmap.indexOf(find) : -1);

	public function getOption(option:String):Null<String>
	{
		for (i in 0...storedBeatmap.length)
		{
			if (storedBeatmap[i].toLowerCase().startsWith(option.toLowerCase() + ":"))
				return storedBeatmap[i].substring(storedBeatmap[i].lastIndexOf(":") + 1).trim();
		}

		return null;
	}

	public function line(string:String, index:Int, split:String):String
	{
		if (string == null)
			return "";

		return string.split(split)[index];
	}
}

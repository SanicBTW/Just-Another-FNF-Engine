package base.osu;

import base.SoundManager.AudioStream;
import funkin.notes.Note;
import openfl.Assets;

using StringTools;

class BeatmapConverter
{
	private static var beatmap:Beatmap;

	private static var noteMap:Map<Int, Int> = [64 => 1, 192 => 2, 320 => 3, 448 => 4];

	private static var noteArray = [
		numberArray(0, 127), numberArray(128, 255), numberArray(256, 383), numberArray(384, 511),
		numberArray(0, 127), numberArray(128, 255), numberArray(256, 383), numberArray(384, 511)
	];

	public static function convert(song:String)
	{
		var map:Array<String> = Assets.getText(Paths.getLibraryPath('$song/${song}.osu', "osu!beatmaps")).split("\n");
		beatmap = new Beatmap(map);

		trace('${map.length - (beatmap.find("[HitObjects]") + 1)} notes');

		beatmap.AudioFile = beatmap.getOption("AudioFilename");

		beatmap.Artist = beatmap.getOption("Artist");
		beatmap.ArtistUnicode = beatmap.getOption("ArtistUnicode");

		beatmap.Title = beatmap.getOption("Title");
		beatmap.TitleUnicode = beatmap.getOption("TitleUnicode");

		trace("Calc bpm");

		var bpm:Float = 0;
		var bpmCount:Float = 0;

		for (i in beatmap.find('[TimingPoints]')...(beatmap.find('[HitObjects]') - 2))
		{
			if (map[i].split(",")[6] == "1")
			{
				bpm = bpm + Std.parseFloat(map[i].split(",")[1]);
				bpmCount++;
			}
			beatmap.BPM = bpm / bpmCount;
		}

		Conductor.changeBPM(beatmap.BPM);

		trace("parse notes");

		for (i in (beatmap.find("[HitObjects]") + 1)...map.length)
		{
			var noteHold:Int = Std.parseInt(beatmap.line(map[i], 5, ','));

			beatmap.Notes.push(new Note(Std.parseInt(beatmap.line(map[i], 2, ',')) * (4 * (1000 * 60 / beatmap.BPM))
				+ (noteHold > 0 ? (Conductor.stepCrochet * (i + 1)) : 0),
				convertNote(beatmap.line(map[i], 0, ",")), 0, (noteHold > 0 ? beatmap.Notes[Std.int(beatmap.Notes.length - 1)] : null), (noteHold > 0)));
		}

		Conductor.boundSong = new AudioStream();
		Conductor.boundSong.audioSource = Cache.getSound(Paths.getLibraryPath('$song/${beatmap.AudioFile.replace(".mp3", ".ogg")}', "osu!beatmaps"));
		SoundManager.addSound(Conductor.boundSong);

		return beatmap;
	}

	private static function numberArray(?min = 0, max:Int):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	private static function convertNote(from_note:Dynamic)
	{
		from_note = Std.parseInt(from_note);

		for (i in 0...noteArray.length)
		{
			for (i2 in 0...noteArray[i].length)
			{
				if (noteArray[i][i2] == from_note)
				{
					return i;
				}
			}
		}

		return 0;
	}
}

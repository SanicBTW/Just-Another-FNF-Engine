package funkin;

import base.Conductor;
import base.MusicBeatState.MusicHandler;
import base.Song;
import flixel.FlxG;
import flixel.util.FlxSort;
import funkin.notes.Note;
import openfl.Assets;

using StringTools;

// actually the note speed is updated on play state LMAO
// mix between my fork of forever and the hxs-forever branch of my 0.3.2h repo, although forever uses another type of shit so most of this is from the 0.3.2h branch
class ChartLoader
{
	public static var unspawnedNotesList:Array<Note> = [];
	public static var difficultyMap:Map<Int, Array<String>> = [0 => ['-easy'], 1 => [''], 2 => ['-hard']];

	public static function loadChart(state:MusicHandler, songName:String, difficulty:Int):SwagSong
	{
		unspawnedNotesList = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		// just in case lol
		var formattedSongName:String = Paths.formatString(songName);
		var rawChart:String = Assets.getText(Paths.getPath('$formattedSongName/$formattedSongName${difficultyMap[difficulty][0]}.json', "songs")).trim();
		var swagChart:SwagSong = Song.loadFromRaw(rawChart);

		Conductor.bindSong(state, Paths.inst(songName), swagChart.bpm, Paths.voices(songName));
		for (section in swagChart.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				switch (songNotes[1])
				{
					default:
						var stepTime:Float = songNotes[0];
						var noteData:Int = Std.int(songNotes[1]);
						var hitNote:Bool = section.mustHitSection;

						if (songNotes[1] > 3) // nº of keys
							hitNote = !section.mustHitSection;

						var oldNote:Note = null;
						if (unspawnedNotesList.length > 0)
							oldNote = unspawnedNotesList[Std.int(unspawnedNotesList.length - 1)];

						var swagNote:Note = new Note(stepTime, noteData, oldNote, false);
						swagNote.mustPress = hitNote;
						swagNote.sustainLength = songNotes[2];
						swagNote.noteSpeed = swagChart.speed;
						swagNote.scrollFactor.set();
						unspawnedNotesList.push(swagNote);

						var susLength:Float = swagNote.sustainLength;
						susLength = susLength / Conductor.stepCrochet;

						if (susLength > 0)
							swagNote.isParent = true;

						for (susNote in 0...Math.floor(susLength + 1))
						{
							oldNote = unspawnedNotesList[Std.int(unspawnedNotesList.length - 1)];

							var sussyNote:Note = new Note(stepTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, noteData, oldNote, true);
							sussyNote.mustPress = hitNote;
							sussyNote.scrollFactor.set();
							sussyNote.noteSpeed = oldNote.noteSpeed;
							sussyNote.parent = swagNote;
							swagNote.children.push(sussyNote);
							if (sussyNote.mustPress)
								sussyNote.x += FlxG.width / 2;
							unspawnedNotesList.push(sussyNote);
						}

						if (swagNote.mustPress)
							swagNote.x += FlxG.width / 2;
					case -1:
						trace("Found event");
				}
			}
		}

		unspawnedNotesList.sort(sortByShit);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagChart;
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.stepTime, Obj2.stepTime);
	}
}

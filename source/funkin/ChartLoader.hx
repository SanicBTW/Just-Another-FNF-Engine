package funkin;

import base.Conductor;
import flixel.util.FlxSort;
import funkin.SongTools;
import funkin.notes.Note;
import openfl.utils.Assets;

using StringTools;

class ChartLoader
{
	public static var unspawnedNotes:Array<Note> = [];
	public static var difficultyMap:Map<Int, Array<String>> = [0 => ['-easy'], 1 => [''], 2 => ['-hard']];

	public static function loadChart(songName:String, difficulty:Int):SongData
	{
		unspawnedNotes = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		var swagSong:SongData = null;

		var formattedSongName:String = Paths.formatString(songName);
		var rawChart:String = Assets.getText(Paths.getPath('songs/$formattedSongName/$formattedSongName${difficultyMap[difficulty][0]}.json', TEXT)).trim();
		swagSong = SongTools.loadSong(rawChart);

		Conductor.bindSong(swagSong, Paths.inst(songName), Paths.voices(songName));

		parseNotes(swagSong);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	public static function parseNotes(swagSong:SongData)
	{
		for (section in swagSong.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				switch (songNotes[1])
				{
					default:
						var strumTime:Float = songNotes[0];
						var noteData:Int = Std.int(songNotes[1] % 4);
						var hitNote:Bool = section.mustHitSection;

						if (songNotes[1] > 3)
							hitNote = !section.mustHitSection;

						var strumLine:Int = (hitNote ? 1 : 0);

						var oldNote:Note = null;
						if (unspawnedNotes.length > 0)
							oldNote = unspawnedNotes[Std.int(unspawnedNotes.length - 1)];

						var newNote:Note = new Note(strumTime, noteData, strumLine, oldNote);
						newNote.mustPress = hitNote;
						newNote.sustainLength = songNotes[2];
						newNote.noteType = songNotes[3];
						unspawnedNotes.push(newNote);

						var holdLength:Float = newNote.sustainLength;
						holdLength = holdLength / Conductor.stepCrochet;

						if (holdLength > 0)
						{
							var holdFloor:Int = Std.int(holdLength + 1);
							for (i in 0...holdFloor)
							{
								var sustainNote:Note = new Note(strumTime + (Conductor.stepCrochet * (i + 1)), noteData, strumLine,
									unspawnedNotes[Std.int(unspawnedNotes.length - 1)], true);
								sustainNote.mustPress = hitNote;
								sustainNote.noteType = newNote.noteType;

								sustainNote.parent = newNote;
								sustainNote.isSustainEnd = (i == holdFloor - 1);
								newNote.children.push(sustainNote);

								unspawnedNotes.push(sustainNote);
							}
						}

					case -1:
						trace("Event");
				}
			}
		}

		unspawnedNotes.sort(sortByShit);
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
}

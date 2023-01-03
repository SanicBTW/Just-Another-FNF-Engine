package funkin;

import base.Conductor;
import base.MusicBeatState.MusicHandler;
import flixel.FlxG;
import flixel.util.FlxSort;
import funkin.CoolUtil;
import funkin.notes.Note;
import haxe.Json;
import openfl.Assets;

using StringTools;

typedef Section =
{
	var sectionNotes:Array<Dynamic>;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var gfSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var altAnim:Bool;
}

typedef Song =
{
	var song:String;
	var notes:Array<Section>;
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
	var validScore:Bool;
}

// actually the note speed is updated on play state LMAO
// mix between my fork of forever and the hxs-forever branch of my 0.3.2h repo, although forever uses another type of shit so most of this is from the 0.3.2h branch
class ChartLoader
{
	public static var unspawnedNoteList:Array<Note> = [];
	public static var difficultyMap:Map<Int, Array<String>> = [0 => ['-easy'], 1 => [''], 2 => ['-hard']];

	public static function loadChart(state:MusicHandler, songName:String, difficulty:Int):Song
	{
		unspawnedNoteList = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		// just in case lol
		var formattedSongName:String = Paths.formatString(songName);
		var rawChart:String = Assets.getText(Paths.getPath('$formattedSongName/$formattedSongName${difficultyMap[difficulty][0]}.json', "songs")).trim();
		var swagSong:Song = CoolUtil.loadSong(rawChart);

		Conductor.bindSong(state, Paths.inst(songName), swagSong.bpm, Paths.voices(songName));

		for (section in swagSong.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				switch (songNotes[1])
				{
					default:
						var stepTime:Float = (songNotes[0] / Conductor.stepCrochet);
						var noteData:Int = Std.int(songNotes[1] % 4);
						var hitNote:Bool = section.mustHitSection;

						if (songNotes[1] > 3)
							hitNote = !section.mustHitSection;

						var strumLine:Int = (hitNote ? 1 : 0);
						var holdStep:Float = (songNotes[2] / Conductor.stepCrochet);

						var newNote:Note = new Note(stepTime, noteData, strumLine);
						newNote.mustPress = hitNote;
						unspawnedNoteList.push(newNote);

						if (holdStep > 0)
						{
							newNote.isParent = true;

							var floorStep:Int = Std.int(holdStep + 1);
							for (i in 0...floorStep)
							{
								var sustainNote:Note = new Note(stepTime + (i + 1), noteData, strumLine,
									unspawnedNoteList[Std.int(unspawnedNoteList.length - 1)], true);
								sustainNote.mustPress = hitNote;
								sustainNote.parent = newNote;
								newNote.children.push(sustainNote);
								if (i == floorStep - 1)
									sustainNote.isSustainEnd = true;
								unspawnedNoteList.push(sustainNote);
							}
						}
					case -1:
						trace("Found event");
				}
			}
		}

		unspawnedNoteList.sort(sortByShit);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.stepTime, Obj2.stepTime);
	}
}

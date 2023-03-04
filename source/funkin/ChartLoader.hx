package funkin;

import base.MusicBeatState.MusicHandler;
import base.system.Conductor;
import flixel.FlxG;
import flixel.util.FlxSort;
import funkin.CoolUtil;
import funkin.notes.Note;
import haxe.Json;
import openfl.Assets;
import openfl.media.Sound;

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

// improve the network operations
// mix between my fork of forever and the hxs-forever branch of my 0.3.2h repo, although forever uses another type of shit so most of this is from the 0.3.2h branch
class ChartLoader
{
	public static var unspawnedNoteList:Array<Note> = [];
	public static var difficultyMap:Map<Int, Array<String>> = [0 => ['-easy'], 1 => [''], 2 => ['-hard']];

	public static var netChart:String = null;
	public static var netInst:Sound = null;
	public static var netVoices:Sound = null;

	public static function loadChart(state:MusicHandler, songName:String, difficulty:Int):Song
	{
		Conductor.bpmChangeMap = [];
		unspawnedNoteList = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		var swagSong:Song = null;
		if (netChart == null)
		{
			// just in case lol
			var formattedSongName:String = Paths.formatString(songName);
			var rawChart:String = Assets.getText(Paths.getPath('$formattedSongName/$formattedSongName${difficultyMap[difficulty][0]}.json', "songs")).trim();
			swagSong = CoolUtil.loadSong(rawChart);

			Conductor.bindSong(state, Paths.inst(songName), swagSong, Paths.voices(songName));
		}
		else
		{
			swagSong = CoolUtil.loadSong(netChart);
			Conductor.bindSong(state, netInst, swagSong, netVoices);
		}

		parseNotes(swagSong);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	private static function parseNotes(swagSong:Song)
	{
		var noteStrumTimes:Map<Int, Array<Float>> = [0 => [], 1 => []];

		var curBPM:Float = swagSong.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (section in swagSong.notes)
		{
			if (section.changeBPM && section.bpm != curBPM)
			{
				curBPM = section.bpm;
				var bpmChange:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: (Conductor.calculateCrochet(curBPM) / 4)
				};
				Conductor.bpmChangeMap.push(bpmChange);
			}

			totalSteps += section.lengthInSteps;
			totalPos += (Conductor.calculateCrochet(curBPM) / 4) * section.lengthInSteps;

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
						var holdStep:Float = (songNotes[2] / Conductor.stepCrochet);

						var newNote:Note = new Note(strumTime, noteData, strumLine);
						newNote.mustPress = hitNote;
						unspawnedNoteList.push(newNote);

						if (noteStrumTimes[strumLine].contains(strumTime))
						{
							newNote.doubleNote = true;
							noteStrumTimes[strumLine].push(strumTime);
						}
						noteStrumTimes[strumLine].push(strumTime);
						if (holdStep > 0)
						{
							var floorStep:Int = Std.int(holdStep + 1);
							for (i in 0...floorStep)
							{
								var sustainNote:Note = new Note(strumTime + (Conductor.stepCrochet * (i + 1)), noteData, strumLine,
									unspawnedNoteList[Std.int(unspawnedNoteList.length - 1)], true);
								sustainNote.mustPress = hitNote;
								sustainNote.parent = newNote;
								newNote.children.push(sustainNote);
								if (i == floorStep - 1)
									sustainNote.isSustainEnd = true;
								unspawnedNoteList.push(sustainNote);

								if (noteStrumTimes[strumLine].contains(strumTime))
								{
									sustainNote.doubleNote = true;
									noteStrumTimes[strumLine].push(strumTime);
								}
								noteStrumTimes[strumLine].push(strumTime);
							}
						}
					case -1:
						trace("Found event");
				}
			}
		}

		unspawnedNoteList.sort(sortByShit);
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
}

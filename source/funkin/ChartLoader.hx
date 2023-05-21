package funkin;

import backend.IO;
import base.Conductor;
import flixel.util.FlxSort;
import funkin.SongTools;
import funkin.notes.Note;
import haxe.io.Path;
import openfl.utils.Assets;

using StringTools;

class ChartLoader
{
	public static var noteQueue:Array<Note> = [];
	public static var strDiffMap:Map<Int, String> = [0 => '-easy', 1 => '', 2 => '-hard'];
	public static var intDiffMap:Map<String, Int> = ['-easy' => 0, '' => 1, "-hard" => 2];

	public static function loadChart(songName:String, difficulty:Int):SongData
	{
		Conductor.bpmChanges = [];
		noteQueue = [];
		var startTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end

		var rawChart:String = "";
		var swagSong:SongData = null;

		if (songName.contains("temp") || songName.contains("persistent"))
		{
			songName = Path.withoutExtension(songName);

			rawChart = cast IO.getFile('${songName}_chart.json', CONTENT);
		}
		else
		{
			var formattedSongName:String = Paths.formatString(songName);
			rawChart = Assets.getText(Paths.getPath('songs/$formattedSongName/$formattedSongName${strDiffMap[difficulty]}.json', TEXT)).trim();
		}

		swagSong = SongTools.loadSong(rawChart);

		Conductor.bindSong(swagSong, Paths.inst(songName), Paths.voices(songName));

		parseNotes(swagSong);

		var endTime:Float = #if sys Sys.time(); #else Date.now().getTime(); #end
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	private static function parseNotes(swagSong:SongData)
	{
		var curChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: swagSong.bpm,
			stepCrochet: Conductor.stepCrochet
		};
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
				Conductor.bpmChanges.push(bpmChange);
				curChange = bpmChange;
			}

			var deltaSteps:Int = (section.sectionBeats != null ? Math.round(section.sectionBeats) * 4 : section.lengthInSteps);
			totalSteps += deltaSteps;
			totalPos += (Conductor.calculateCrochet(curBPM) / 4) * deltaSteps;

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
						if (noteQueue.length > 0)
							oldNote = noteQueue[Std.int(noteQueue.length - 1)];

						var newNote:Note = new Note(strumTime, noteData, strumLine, oldNote);
						newNote.mustPress = hitNote;
						newNote.sustainLength = Math.round(songNotes[2] / curChange.stepCrochet) * curChange.stepCrochet;
						newNote.noteType = songNotes[3];
						noteQueue.push(newNote);

						var holdLength:Float = newNote.sustainLength;
						holdLength = holdLength / curChange.stepCrochet;

						if (Math.round(holdLength) > 0)
						{
							for (note in 0...Math.round(holdLength))
							{
								var time:Float = strumTime + (curChange.stepCrochet * note) + curChange.stepCrochet;

								var sustainNote:Note = new Note(time, noteData, strumLine, noteQueue[Std.int(noteQueue.length - 1)], true);
								sustainNote.mustPress = hitNote;
								sustainNote.noteType = newNote.noteType;

								sustainNote.parent = newNote;
								sustainNote.isSustainEnd = (note == Math.round(holdLength) - 1);

								newNote.tail.push(sustainNote);
								newNote.unhitTail.push(sustainNote);

								noteQueue.push(sustainNote);
							}
						}

					case -1:
						trace("Event");
				}
			}
		}

		noteQueue.sort(sortByShit);
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
}

package funkin;

import backend.IO;
import backend.ScriptHandler;
import base.Conductor;
import flixel.util.FlxSort;
import funkin.Events.EventNote;
import funkin.SongTools;
import funkin.notes.Note;
import haxe.io.Path;
import openfl.media.Sound;
import openfl.utils.Assets;

using StringTools;

typedef EventInit =
{
	var module:ForeverModule;
	var value1:String;
	var value2:String;
}

// Rewrite this or something
class ChartLoader
{
	public static var noteQueue:Array<Note> = [];
	public static var eventQueue:Array<EventNote> = [];
	public static var strDiffMap:Map<Int, String> = [0 => '-easy', 1 => '', 2 => '-hard'];
	public static var intDiffMap:Map<String, Int> = ['-easy' => 0, '' => 1, "-hard" => 2];

	// Dumb queue/fix to init events post PlayState creation to avoid error
	private static var initQueue:Array<EventInit> = [];

	public static function loadFSChart(songName:String):SongData
	{
		resetQueues();
		var startTime:Float = haxe.Timer.stamp();

		var rawChart:String = IO.getSong(songName, CHART, 1);
		var inst:Sound = IO.getSong(songName, INST);
		var vocals:Null<Sound> = IO.getSong(songName, VOICES);

		var swagSong:SongData = SongTools.loadSong(rawChart);
		if (vocals == null)
			swagSong.needsVoices = false;

		Conductor.bindSong(swagSong, inst, vocals);

		parseNotes(swagSong);

		var endTime:Float = haxe.Timer.stamp();
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	public static function loadNetChart(rawChart:String, inst:Sound, ?vocals:Sound):SongData
	{
		resetQueues();
		var startTime:Float = haxe.Timer.stamp();

		var swagSong:SongData = SongTools.loadSong(rawChart);
		if (vocals == null)
			swagSong.needsVoices = false;

		Conductor.bindSong(swagSong, inst, vocals);

		parseNotes(swagSong);

		var endTime:Float = haxe.Timer.stamp();
		trace('end chart parse time ${endTime - startTime}');

		return swagSong;
	}

	public static function loadChart(songName:String, difficulty:Int):SongData
	{
		resetQueues();
		var startTime:Float = haxe.Timer.stamp();

		var formattedSongName:String = Paths.formatString(songName);
		var rawChart:String = Assets.getText(Paths.getPath('songs/$formattedSongName/$formattedSongName${strDiffMap[difficulty]}.json', TEXT)).trim();
		var swagSong:SongData = SongTools.loadSong(rawChart);

		// should be handled by the binding method smh
		Conductor.bindSong(swagSong, Paths.inst(songName), Paths.voices(songName));

		parseNotes(swagSong);

		var endTime:Float = haxe.Timer.stamp();
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

						var newNote:Note = new Note(strumTime, noteData, songNotes[3], strumLine, oldNote);
						newNote.mustPress = hitNote;
						var holdStep:Float = newNote.sustainLength = songNotes[2] / curChange.stepCrochet;
						noteQueue.push(newNote);

						if (holdStep > 0)
						{
							var floorStep:Int = Std.int(holdStep + 1);
							for (note in 0...floorStep)
							{
								var sustainNote:Note = new Note(strumTime + (curChange.stepCrochet * (note + 1)), noteData, newNote.noteType, strumLine,
									noteQueue[Std.int(noteQueue.length - 1)], true);
								sustainNote.mustPress = hitNote;

								sustainNote.parent = newNote;
								sustainNote.isSustainEnd = (note == floorStep);
								sustainNote.spotHold = note;

								newNote.tail.push(sustainNote);

								noteQueue.push(sustainNote);
							}
						}

					case -1:
						trace('event');
						pushEvent(songNotes);
				}
			}
		}

		for (eventNotes in swagSong.events)
		{
			pushEvent(eventNotes);
		}

		noteQueue.sort(sortByShit);
	}

	private static function pushEvent(eventParams:Array<Dynamic>)
	{
		for (i in 0...eventParams[1].length)
		{
			var newEventNote:Array<Dynamic> = [eventParams[0], eventParams[1][i][0], eventParams[1][i][1], eventParams[1][i][2]];
			var subEvent:EventNote = {
				strumTime: newEventNote[0],
				event: newEventNote[1],
				value1: newEventNote[2],
				value2: newEventNote[3]
			};
			trace(subEvent);

			if (subEvent.event.length > 0 && Events.eventList.contains(subEvent.event))
			{
				var mySelectedEvent:String = Events.eventList[Events.eventList.indexOf(subEvent.event)];
				if (mySelectedEvent != null)
				{
					var module:ForeverModule = Events.loadedModules.get(subEvent.event);
					var delay:Float = 0;
					if (module.exists("returnDelay"))
						delay = module.get("returnDelay")();

					subEvent.strumTime -= delay;

					initQueue.push({module: module, value1: subEvent.value1, value2: subEvent.value2});
					eventQueue.push(subEvent);
				}
			}
		}
	}

	// dumb fix sorry
	public static function initEvents()
	{
		for (event in initQueue)
		{
			if (event.module.exists('initFunction'))
				event.module.get('initFunction')(event.value1, event.value2);
		}
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private static function resetQueues()
	{
		Conductor.bpmChanges = [];
		noteQueue = [];
		eventQueue = [];
		initQueue = [];
	}
}

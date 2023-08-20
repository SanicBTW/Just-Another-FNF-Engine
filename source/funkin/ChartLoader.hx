package funkin;

import backend.*;
import backend.Conductor;
import backend.scripting.ForeverModule;
import flixel.util.FlxSort;
import funkin.Events.EventNote;
import funkin.SongTools;
import funkin.notes.Note;
import openfl.media.Sound;
import openfl.utils.Assets;
import quaver.*;

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

	// osu support soon
	public static function loadBeatmap(mapID:String):Qua
	{
		resetQueues();
		var startTime:Float = haxe.Timer.stamp();

		var qua:Qua = QuaverDB.loadedMaps.get(mapID);
		@:privateAccess
		qua.parseObjects();

		for (samplePath in qua.CustomAudioSamples)
		{
			Cache.getSound(samplePath);
		}

		var swagSong:SongData = {
			song: '${qua.Artist} - ${qua.Title} (${qua.DifficultyName})',
			validScore: true,
			arrowSkin: "default",
			stage: "quaver",
			player1: "",
			player2: "",
			player3: "",
			gfVersion: "",
			needsVoices: false,
			bpm: qua.TimingPoints[0].Bpm,
			speed: 3.2, // Soon Quaver will use user speed
			notes: [],
			events: []
		};
		var audioFile:Sound = Cache.getSound(#if FS_ACCESS backend.io.Path.join(IO.getFolderPath(QUAVER), '${qua.MapSetId}',
			qua.AudioFile) #else Paths.file('quaver/${qua.MapSetId}/${qua.AudioFile}') #end);

		flixel.FlxG.sound.playMusic(audioFile, 1, false);
		flixel.FlxG.sound.music.stop();
		Conductor.bpm = qua.TimingPoints[0].Bpm;
		Conductor.speed = swagSong.speed;
		Conductor.SONG = swagSong;

		for (hitObject in qua.HitObjects)
		{
			var strumTime:Float = hitObject.StartTime;
			var noteData:Int = Std.int(hitObject.Lane % 4);
			var endTime:Float = hitObject.EndTime;

			var oldNote:Note = null;
			if (noteQueue.length > 0)
				oldNote = noteQueue[Std.int(noteQueue.length - 1)];

			var newNote:Note = new Note(strumTime, noteData, "default", 1, oldNote);
			newNote.mustPress = true;
			var holdStep:Float = newNote.sustainLength = (endTime > 0) ? (endTime - strumTime) / Conductor.stepCrochet : 0;
			noteQueue.push(newNote);

			if (holdStep > 0)
			{
				var floorStep:Int = Std.int(holdStep + 1);
				for (note in 0...floorStep)
				{
					var time:Float = strumTime + (Conductor.stepCrochet * (note + 1));
					var sustainNote:Note = new Note(time, noteData, newNote.noteType, 1, noteQueue[Std.int(noteQueue.length - 1)], true);

					sustainNote.mustPress = newNote.mustPress;
					sustainNote.parent = newNote;
					sustainNote.isSustainEnd = (note == floorStep);
					sustainNote.spotHold = note;

					newNote.tail.push(sustainNote);

					noteQueue.push(sustainNote);
				}
			}
		}

		noteQueue.sort(sortByShit);

		var endTime:Float = haxe.Timer.stamp();
		trace('end chart parse time ${endTime - startTime}');

		return qua;
	}

	private static function parseNotes(swagSong:SongData)
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
						if (noteQueue.length > 0)
							oldNote = noteQueue[Std.int(noteQueue.length - 1)];

						var newNote:Note = new Note(strumTime, noteData, songNotes[3], strumLine, oldNote);
						newNote.mustPress = hitNote;
						var holdStep:Float = newNote.sustainLength = songNotes[2] / Conductor.stepCrochet;
						noteQueue.push(newNote);

						if (holdStep > 0)
						{
							var floorStep:Int = Std.int(holdStep + 1);
							for (note in 0...floorStep)
							{
								var sustainNote:Note = new Note(strumTime + (Conductor.stepCrochet * (note + 1)), noteData, newNote.noteType, strumLine,
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

			if (subEvent.event.length > 0 && Events.addEvent(subEvent.event))
			{
				var module:ForeverModule = Events.loadedModules.get(subEvent.event);

				if (module == null)
					return;

				var delay:Float = 0;
				if (module.exists("returnDelay"))
					delay = module.get("returnDelay")();

				subEvent.strumTime -= delay;

				eventQueue.push(subEvent);
			}
		}
	}

	private static function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private static function resetQueues()
	{
		Events.loadedModules.clear();
		@:privateAccess
		Events.eventList = IO.getFolderFiles(EVENTS);

		Conductor.reset();

		noteQueue = [];
		eventQueue = [];
	}
}

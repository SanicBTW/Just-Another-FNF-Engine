package funkin;

import backend.*;
import backend.Conductor;
import backend.scripting.ForeverModule;
import flixel.util.FlxSort;
import funkin.Events.EventNote;
import funkin.SongTools;
import funkin.notes.Note;
import haxe.ds.DynamicMap;
import haxe.io.Bytes;
import network.MultiCallback;
import openfl.media.Sound;
import openfl.utils.Assets;
import openfl.utils.ByteArray;
import quaver.*;

using StringTools;

typedef EventInit =
{
	var module:ForeverModule;
	var value1:String;
	var value2:String;
}

typedef VirtSong =
{
	var chart:SongData;
	var inst:Bytes;
	var voices:Null<Bytes>;
}

// Rewrite this or something
// Use cache
class ChartLoader
{
	public static var noteQueue:Array<Note> = [];
	public static var eventQueue:Array<EventNote> = [];
	public static var strDiffMap:Map<Int, String> = [0 => '-easy', 1 => '', 2 => '-hard'];
	public static var intDiffMap:Map<String, Int> = ['-easy' => 0, '' => 1, "-hard" => 2];
	public static var overridenLoad:Bool = false;

	// Tried using cache but it breaks the whole shit, late cache they say!
	public static function loadVFSChart(songName:String, loadSounds:Bool = true):SPromise<SongData>
	{
		resetQueues();
		var startTime:Float = haxe.Timer.stamp();

		return new SPromise<SongData>((resolve, reject) ->
		{
			Save.database.shouldPreprocess = false;

			// Surely NOT null
			Save.database.get(VFS, songName).then((s) ->
			{
				var song:VirtSong = cast s;

				if (loadSounds)
				{
					var inst:Sound = null;
					var vocals:Null<Sound> = null;

					var multCb:MultiCallback = new MultiCallback(() ->
					{
						Conductor.bindSong(song.chart, inst, vocals);
						parseNotes(song.chart);

						var endTime:Float = haxe.Timer.stamp();
						trace('end chart parse time ${endTime - startTime}');

						resolve(song.chart);
					});

					var instCb:() -> Void = multCb.add('inst:$songName');
					var voicesCb:() -> Void = multCb.add('voices:$songName');

					#if !js
					var ibyteArray:ByteArray = ByteArray.fromBytes(song.inst);
					#else
					@:privateAccess
					var ibyteArray:ByteArray = ByteArray.fromArrayBuffer(song.inst.b.buffer);
					#end
					Extensions.loadFromBytes(ibyteArray).then((audioBuffer) ->
					{
						inst = Sound.fromAudioBuffer(audioBuffer);
						instCb();
					});

					if (song.voices != null)
					{
						#if !js
						var byteArray:ByteArray = ByteArray.fromBytes(song.voices);
						#else
						@:privateAccess
						var byteArray:ByteArray = ByteArray.fromArrayBuffer(song.voices.b.buffer);
						#end

						Extensions.loadFromBytes(byteArray).then((audioBuffer) ->
						{
							vocals = Sound.fromAudioBuffer(audioBuffer);
							voicesCb();
						});
					}
					else
						voicesCb();
				}
				else
				{
					Conductor.SONG = song.chart;
					resolve(song.chart);
				}
			});
		});
	}

	public static function loadFSChart(songName:String, songDiff:Int = 1):SongData
	{
		resetQueues();
		var startTime:Float = haxe.Timer.stamp();

		var rawChart:String = IO.getSong(songName, CHART, songDiff);
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
		// Let me get this straight, SO YOU ARE TELLING ME THIS SHIT IS RETURNING NULL WHEN THE QUAVER LIBRARY IS LOADED FROM THE PREVIOUS STATE????
		// yknow what just gonna enforce library fuck it
		var audioFile:Sound = Cache.getSound(#if FS_ACCESS backend.io.Path.join(IO.getFolderPath(QUAVER), '${qua.MapSetId}',
			qua.AudioFile) #else 'quaver:assets/quaver/${qua.MapSetId}/${qua.AudioFile}' #end); // assuming the librarry is loaded (IT IS)

		flixel.FlxG.sound.playMusic(audioFile, 1, false);
		flixel.FlxG.sound.music.stop();
		Conductor.changeBPM(qua.TimingPoints[0].Bpm);
		Conductor.speed = swagSong.speed;
		Conductor.SONG = swagSong;

		for (hitObject in qua.HitObjects)
		{
			var strumTime:Float = hitObject.StartTime;
			var noteData:Int = Std.int(hitObject.Lane - 1);
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
				// Set the new note as parent indicating that is the head of a sustain (becareful its referencing itself)
				newNote.parent = newNote;

				var floorStep:Int = Math.floor(holdStep);
				for (note in 0...floorStep + 2)
				{
					var time:Float = strumTime + (Conductor.stepCrochet * note) + (Conductor.stepCrochet / Conductor.speed);
					var sustainNote:Note = new Note(time, noteData, newNote.noteType, 1, noteQueue[Std.int(noteQueue.length - 1)], true);

					sustainNote.mustPress = newNote.mustPress;
					sustainNote.parent = newNote;
					sustainNote.spotHold = note;

					newNote.tail.push(sustainNote);

					noteQueue.push(sustainNote);
				}

				// Instead of depending on floorStep, just set the last pushed note from the note parent as sustain end
				if (newNote.tail[newNote.tail.length - 1] != null)
					newNote.tail[newNote.tail.length - 1].isSustainEnd = true;
			}
		}

		noteQueue.sort(sortByShit);

		var endTime:Float = haxe.Timer.stamp();
		trace('end chart parse time ${endTime - startTime}');

		return qua;
	}

	private static function parseNotes(swagSong:SongData)
	{
		var noteTimes:DynamicMap<Int, Array<Float>> = new DynamicMap<Int, Array<Float>>();

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
						newNote.gfNote = (section.gfSection || songNotes[3] == "GF Sing"); // force
						newNote.doubleNote = checkDouble(noteTimes, strumLine, strumTime);
						var holdStep:Float = newNote.sustainLength = songNotes[2] / Conductor.stepCrochet;
						noteQueue.push(newNote);

						if (holdStep > 0)
						{
							// Set the new note as parent indicating that is the head of a sustain (becareful its referencing itself)
							newNote.parent = newNote;

							var floorStep:Int = Math.floor(holdStep);
							for (note in 0...floorStep + 2)
							{
								var time:Float = strumTime + (Conductor.stepCrochet * note) + (Conductor.stepCrochet / Conductor.speed);
								var sustainNote:Note = new Note(time, noteData, newNote.noteType, strumLine, noteQueue[Std.int(noteQueue.length - 1)], true);

								// when setting a parent, set the properties directly on set_parent(parent:Note) on Note
								sustainNote.mustPress = hitNote;
								sustainNote.doubleNote = checkDouble(noteTimes, strumLine, time);
								sustainNote.gfNote = newNote.gfNote;
								sustainNote.parent = newNote;
								sustainNote.spotHold = note;

								newNote.tail.push(sustainNote);

								noteQueue.push(sustainNote);
							}

							// Instead of depending on floorStep, just set the last pushed note from the note parent as sustain end
							if (newNote.tail[newNote.tail.length - 1] != null)
								newNote.tail[newNote.tail.length - 1].isSustainEnd = true;
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

	private static function checkDouble(map:DynamicMap<Int, Array<Float>>, lane:Int, time:Float):Bool
	{
		if (!map.exists(lane))
			map[lane] = [];

		var ret:Bool = map[lane].contains(time);
		if (!ret)
			map[lane].push(time);

		return ret;
	}
}

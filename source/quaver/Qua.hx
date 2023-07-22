package quaver;

using StringTools;
using backend.Extensions;

#if FS_ACCESS
import backend.IO;
import haxe.io.Path;
#end

typedef TimingPoint =
{
	StartTime:Float,
	Bpm:Float
}

typedef SliderVelocity =
{
	StartTime:Float,
	Multiplier:Float
}

typedef HitObject =
{
	StartTime:Float,
	Lane:Int,
	?EndTime:Float,
	KeySounds:Array<Dynamic>
}

enum abstract KeyMode(String) to String
{
	var Keys4 = "Keys4";
	var Keys7 = "Keys7";
}

// Quaver Map but file extension
// Never going to rewrite this

@:publicFields
class Qua
{
	var AudioFile:String = '';
	var SongPreviewTime:Float = 0;
	var BackgroundFile:String = '';
	var MapId:Int = 0;
	var MapSetId:Int = 0;
	var Mode:KeyMode = Keys4;
	var Title:String = '';
	var Artist:String = '';
	var Source:String = '';
	var Tags:String = '';
	var Creator:String = '';
	var DifficultyName:String = '';
	var Description:String = '';
	var BPMDoesNotAffectScrollVelocity:Bool = true;
	var InitialScrollVelocity:Float = 1;

	var EditorLayers:Array<Dynamic> = []; // Dunno what is this actually
	var CustomAudioSamples:Array<Dynamic> = []; // Neither this
	var SoundEffects:Array<Dynamic> = []; // Uhhh

	var TimingPoints:Array<TimingPoint> = [];
	var SliderVelocities:Array<SliderVelocity> = [];
	var HitObjects:Array<HitObject> = [];

	private final exclusions:Array<String> = [
		'HitObjects',
		'TimingPoints',
		'SliderVelocities',
		// Arrays
		'EditorLayers',
		'CustomAudioSamples',
		'SoundEffects',
	];

	private var fields:Array<String> = [];

	@:noCompletion
	// Instead of parsing it, just do a quick search and that shit yknow
	private var lines:Array<String> = [];

	// 2 worked fine for a long ass time????
	final length_min:Int = 1;

	function new(rawContent:String, parse:Bool = true)
	{
		// should I do a regex?
		lines = rawContent.trim().split("\n");
		fields = Type.getInstanceFields(Type.getClass(this));

		// Metadata must be parsed, objects are not needed for a menu right
		parseMetadata();
		#if FS_ACCESS convertAudio(); #end

		if (!parse)
			return;

		this.parseObjects();
	}

	function parseMetadata()
	{
		var lastSection:String = '';

		for (line in lines)
		{
			var section:String = line.split(":")[0];
			var value:String = line.split(":")[1];

			if (value.length > length_min
				&& !(exclusions.contains(lastSection) || exclusions.contains(section.trim()))
				&& fields.contains(section))
			{
				Reflect.setField(this, section, value.trim());
				continue;
			}

			if (exclusions.contains(section))
				break;
		}
	}

	function parseObjects()
	{
		var lastSection:String = '';

		for (i in 0...lines.length)
		{
			var section:String = lines[i].split(":")[0];
			var value:Null<String> = lines[i].split(":")[1];

			if (value.length <= length_min || value.trim() == "[]" && section.trim() != "KeySounds")
				lastSection = section;

			// lil check
			if (lastSection != section && section.trim() == "- StartTime")
			{
				// i fucking hate this
				switch (lastSection)
				{
					case 'TimingPoints':
						var timing:TimingPoint = {
							StartTime: Std.parseFloat(value.trim()),
							Bpm: Std.parseFloat(lines[i + 1].split(":")[1])
						};
						TimingPoints.push(timing);

					case 'SliderVelocities':
						var velocity:SliderVelocity = {
							StartTime: Std.parseFloat(value.trim()),
							Multiplier: Std.parseFloat(lines[i + 1].split(":")[1])
						};
						SliderVelocities.push(velocity);

					case 'HitObjects':
						var hitObj:HitObject = {
							StartTime: Std.parseFloat(value.trim()),
							Lane: Std.parseInt(lines[i + 1].split(":")[1]),
							EndTime: 0,
							KeySounds: []
						};

						var secSection:String = lines[i + 2].split(":")[0].trim();
						switch (secSection)
						{
							case 'KeySounds':
								hitObj.KeySounds = cast lines[i + 2].split(":")[1];
							case 'EndTime':
								hitObj.EndTime = Std.parseFloat(lines[i + 2].split(":")[1]);

								// assuming the next section is uhhhhhhhh keysounds
								hitObj.KeySounds = cast lines[i + 3].split(":")[1];
						}
						HitObjects.push(hitObj);
				}
			}
		}
	}

	#if FS_ACCESS
	private function convertAudio()
	{
		var path = Path.join([IO.getFolderPath(QUAVER), '$MapId']);

		// uhhhhhh
		var audioPath:String = Path.join([Sys.getCwd(), "assets", "funkin", "quaver", '$MapId', AudioFile]);
		AudioFile = AudioFile.replace("mp3", "ogg");

		var output:String = Path.join([path, AudioFile]);
		var ffmpeg:String = Path.join([Sys.getCwd(), "ffmpeg.exe"]);

		// aight
		if (!IO.existsOnFolder(QUAVER, '$MapId'))
			sys.FileSystem.createDirectory(path);

		if (sys.FileSystem.exists(output))
			return;

		if (Sys.command('$ffmpeg -i "$audioPath" -c:a libvorbis -q:a 4 "$output" -y') == 0)
			trace('Finished converting audio file');
	}
	#end
	// pending: parsing
	/*
		public static function parse(map:String)
		{
			@:privateAccess
			ChartLoader.resetQueues();

			new QuaverMap(Paths.text(Paths.file('quaver/$map.qua')), (quaverMap:QuaverMap) ->
			{
				test.QuaverTest.map = quaverMap;

				var soundName:String = #if html5 quaverMap.AudioFile #else quaverMap.AudioFile.replace("mp3", "ogg") #end;
				var audioshit = Cache.getSound(Paths.file('quaver/$soundName'));

				Conductor.changeBPM(quaverMap.TimingPoints[0].Bpm);
				Conductor.songSpeed = (Conductor.songRate * 2.7);
				flixel.FlxG.sound.music = new flixel.system.FlxSound().loadEmbedded(audioshit);

				// uses old hold length method
				for (hitObject in quaverMap.HitObjects)
				{
					var strumTime:Float = hitObject.StartTime;
					var noteData:Int = hitObject.Lane - 1; // you fucking dumbass, for some fucking reason 0 1 2 3 basically 4 is null
					var endTime:Float = 0;

					if (hitObject.EndTime > 0)
						endTime = hitObject.EndTime;

					var oldNote:Note = null;
					if (ChartLoader.noteQueue.length > 0)
						oldNote = ChartLoader.noteQueue[Std.int(ChartLoader.noteQueue.length - 1)];

					var newNote:Note = new Note(strumTime, noteData, "default", 1, oldNote);
					var holdStep:Float = newNote.sustainLength = (endTime > 0) ? Math.round((endTime - strumTime) / Conductor.stepCrochet) : 0;
					ChartLoader.noteQueue.push(newNote);

					if (holdStep > 0)
					{
						var floorStep:Int = Std.int(holdStep + 1);
						for (note in 0...floorStep)
						{
							var time:Float = strumTime + (Conductor.stepCrochet * (note + 1));

							var sustainNote:Note = new Note(time, noteData, newNote.noteType, 1, ChartLoader.noteQueue[Std.int(ChartLoader.noteQueue.length - 1)],
								true);
							sustainNote.parent = newNote;
							sustainNote.isSustainEnd = (note == floorStep - 1);

							newNote.tail.push(sustainNote);
							newNote.unhitTail.push(sustainNote);

							ChartLoader.noteQueue.push(sustainNote);
						}
					}
				}
				// flixel.FlxG.sound.music.loopTime = flixel.FlxG.sound.music.time = quaverMap.SongPreviewTime;
			});
	}*/
}

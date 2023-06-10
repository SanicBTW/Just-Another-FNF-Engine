package quaver;

import backend.Cache;
import base.Conductor;
import funkin.ChartLoader;
import funkin.notes.Note;

using StringTools;

typedef TimingPoint =
{
	StartTime:Float,
	Bpm:Float
}

typedef HitObject =
{
	StartTime:Float,
	Lane:Int,
	?EndTime:Float,
	KeySounds:Array<Dynamic>
}

@:publicFields // just make them public wtf
class QuaverMap
{
	var AudioFile:String = '';
	var SongPreviewTime:Float = 0;
	var BackgroundFile:String = '';
	var MapId:Int = 0;
	var MapSetId:Int = 0;
	var Mode:String = 'Keys4';
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
	var SliderVelocities:Array<Dynamic> = []; // What is the type
	var HitObjects:Array<HitObject> = []; // uhhhhhh

	private final exclusions:Array<String> = [
		'HitObjects',
		'TimingPoints',
		// Arrays
		'EditorLayers',
		'CustomAudioSamples',
		'SoundEffects',
		'SliderVelocities'
	];

	private var fields:Array<String> = [];

	// new will parse content directly
	// everything is a fucking integer why the fuck am i parsing it as fucking floating points bruh
	// bro this is probably the worst code ive done lately
	public function new(unparsedContent:String, onFinish:QuaverMap->Void)
	{
		var lastSection:String = '';
		var lines:Array<String> = unparsedContent.trim().split("\n");
		var lastTiming:TimingPoint = null;
		var lastHitObj:HitObject = null;
		fields = Type.getInstanceFields(Type.getClass(this));

		for (i in 0...lines.length)
		{
			try
			{
				var section:String = lines[i].split(":")[0];
				var value:Null<String> = lines[i].split(":")[1];

				if (value.length > 2
					&& !(exclusions.contains(lastSection) || exclusions.contains(section.trim()))
					&& fields.contains(section))
				{
					Reflect.setField(this, section, value.trim());
					trace(section, Reflect.field(this, section));
				}

				// fucking dumbass
				if (section.trim() == "SliderVelocities")
					lastSection = '';

				if (value.length <= 2)
					lastSection = section;

				// lil check
				if (lastSection != section)
				{
					switch (lastSection)
					{
						case 'TimingPoints':
							if (lastTiming == null)
							{
								lastTiming = {
									StartTime: 0,
									Bpm: 0
								};
							}

							// i fucking hate this
							if (section.trim() == "- StartTime")
							{
								lastTiming = {
									StartTime: Std.parseFloat(value.trim()),
									Bpm: Std.parseFloat(lines[i + 1].split(":")[1])
								};
								TimingPoints.push(lastTiming);
							}

						case 'HitObjects':
							if (lastHitObj == null)
							{
								lastHitObj = {
									StartTime: 0,
									KeySounds: [],
									EndTime: 0,
									Lane: 0
								};
							}

							if (section.trim() == "- StartTime")
							{
								lastHitObj = {
									StartTime: Std.parseFloat(value.trim()),
									Lane: Std.parseInt(lines[i + 1].split(":")[1]),
									EndTime: 0,
									KeySounds: []
								};

								var secSection:String = lines[i + 2].split(":")[0].trim();
								switch (secSection)
								{
									case 'KeySounds':
										lastHitObj.KeySounds = cast lines[i + 2].split(":")[1];
									case 'EndTime':
										lastHitObj.EndTime = Std.parseFloat(lines[i + 2].split(":")[1]);

										// assuming the next section is uhhhhhhhh keysounds
										lastHitObj.KeySounds = cast lines[i + 3].split(":")[1];
								}

								HitObjects.push(lastHitObj);
							}
					}
				}
			}
			catch (ex)
			{
				trace(ex);
			}
		}

		onFinish(this);
	}
}

class QuaverParser
{
	public static function parse(map:String)
	{
		@:privateAccess
		ChartLoader.resetQueues();

		new QuaverMap(Paths.text(Paths.file('quaver/$map.qua')), (quaverMap:QuaverMap) ->
		{
			QuaverTest.map = quaverMap;

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
	}
}

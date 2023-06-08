package test;

import backend.Cache;
import base.Conductor;
import funkin.ChartLoader;
import funkin.notes.Note;

using StringTools;

// holds array of lines and metadata
// heavily inspired in https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/6f1ce5b990fc9a332c654828f4813dd7370b9765/source/osu/Beatmap.hx
// and https://github.com/SanicBTW/FNF-PsychEngine-0.3.2h/blob/6f1ce5b990fc9a332c654828f4813dd7370b9765/source/osu/BeatmapConverter.hx
// should just read every line or make a custom parser shit that might be hardcoded

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

	private final exclusions:Array<String> = ['HitObjects', 'TimingPoints'];

	// new will parse content directly
	// everything is a fucking integer why the fuck am i parsing it as fucking floating points bruh
	// bro this is probably the worst code ive done lately
	public function new(unparsedContent:String, onFinish:QuaverMap->Void)
	{
		var lastSection:String = '';
		var lines:Array<String> = unparsedContent.trim().split("\n");
		var lastTiming:TimingPoint = null;
		var lastHitObj:HitObject = null;

		for (i in 0...lines.length)
		{
			try
			{
				var section:String = lines[i].split(":")[0];
				var value:Null<String> = lines[i].split(":")[1];

				if (value.length > 2 && !exclusions.contains(section))
				{
					if (Reflect.hasField(this, section))
						Reflect.setField(this, section, value.trim());
				}

				// fucking dumbass
				if (section == "SliderVelocities")
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
			trace(quaverMap);
			var audioshit = Cache.getSound(Paths.file('quaver/${quaverMap.AudioFile}'));
			Conductor.changeBPM(quaverMap.TimingPoints[0].Bpm);
			flixel.FlxG.sound.music = new flixel.system.FlxSound().loadEmbedded(audioshit);

			for (hitObject in quaverMap.HitObjects)
			{
				var strumTime:Float = hitObject.StartTime;
				var noteData:Int = hitObject.Lane;
				var sustainLength:Float = hitObject.EndTime - hitObject.StartTime;

				trace(sustainLength);

				var oldNote:Note = null;
				if (ChartLoader.noteQueue.length > 0)
					oldNote = ChartLoader.noteQueue[Std.int(ChartLoader.noteQueue.length - 1)];

				var newNote:Note = new Note(strumTime, noteData, "default", 1, oldNote);
				ChartLoader.noteQueue.push(newNote);
			}
			// flixel.FlxG.sound.music.loopTime = flixel.FlxG.sound.music.time = quaverMap.SongPreviewTime;
		});
	}
}

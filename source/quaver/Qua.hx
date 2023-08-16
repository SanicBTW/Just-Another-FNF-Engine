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
	EndTime:Float,
	KeySounds:Array<Dynamic>
}

enum abstract KeyMode(String) to String
{
	var Keys4 = "Keys4";
	var Keys7 = "Keys7";
}

/**
 * v1.0, still needs some structs and optimizations but It's working fine
 * @author SanicBTW
 */
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

	@:noCompletion
	private var fields:Array<String> = [];

	@:noCompletion
	// Instead of parsing it, just do a quick search and that shit yknow
	private var lines:Array<String> = [];

	function new(rawContent:String, parse:Bool = true)
	{
		lines = (~/$\s/gm).split(rawContent.trim());
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

			if (value.length > 1 && !(exclusions.contains(lastSection) || exclusions.contains(section.trim())) && fields.contains(section))
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

			if (value.length <= 1 || value.trim() == "[]" && section.trim() != "KeySounds")
				lastSection = section;

			// lil check
			if (lastSection != section && section.trim() == "- StartTime")
			{
				// i fucking hate this
				switch (lastSection)
				{
					case 'TimingPoints':
						TimingPoints.push({
							StartTime: Std.parseFloat(value.trim()),
							Bpm: Std.parseFloat(lines[i + 1].split(":")[1])
						});

					case 'SliderVelocities':
						SliderVelocities.push({
							StartTime: Std.parseFloat(value.trim()),
							Multiplier: Std.parseFloat(lines[i + 1].split(":")[1])
						});

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
		if (!IO.existsOnFolder(QUAVER, '$MapId'))
			sys.FileSystem.createDirectory(path);

		// uhhhhhh
		var audioPath:String = Path.join([Sys.getCwd(), "assets", "funkin", "quaver", '$MapId', AudioFile]);
		AudioFile = AudioFile.replace("mp3", "ogg");

		var output:String = Path.join([path, AudioFile]);
		if (sys.FileSystem.exists(output))
			return;

		var ffmpeg:String = Path.join([Sys.getCwd(), "ffmpeg.exe"]);
		if (Sys.command('$ffmpeg -i "$audioPath" -c:a libvorbis -q:a 4 "$output" -y') == 0)
			trace('Finished converting audio file');
	}
	#end
}

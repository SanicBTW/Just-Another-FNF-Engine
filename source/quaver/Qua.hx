package quaver;

using StringTools;
using backend.Extensions;

#if FS_ACCESS
import backend.IO;
import backend.io.Path;
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

typedef SoundEffect =
{
	StartTime:Float,
	Sample:Int, // Index for CustomAudioSamples, will instead use that array as Sound cache
	Volume:Float // Will divide this by 100 to get 0.x
}

typedef KeySound =
{
	Sample:Int,
	Volume:Float
}

typedef HitObject =
{
	StartTime:Float,
	Lane:Int,
	EndTime:Float,
	HitSound:Null<String>,
	KeySounds:Null<KeySound> // I don't believe a single HitObject can contain more than 1 KeySound
}

enum abstract KeyMode(String) to String
{
	var Keys4 = "Keys4";
	var Keys7 = "Keys7";
}

/**
 * v1.1
 *
 * Missing editor layers and optimizations but It's working fine
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

	var CustomAudioSamples:Array<String> = []; // I guess it only has the Path line and nothing else
	var SoundEffects:Array<SoundEffect> = [];
	var TimingPoints:Array<TimingPoint> = [];
	var SliderVelocities:Array<SliderVelocity> = [];
	var HitObjects:Array<HitObject> = [];

	private final exclusions:Array<String> = [
		'EditorLayers',
		'CustomAudioSamples',
		'SoundEffects',
		'TimingPoints',
		'SliderVelocities',
		'HitObjects'
	];

	@:noCompletion
	private var fields:Array<String> = [];

	@:noCompletion
	// Instead of parsing it, just do a quick search and that shit yknow
	private var lines:Array<String> = [];

	function new(rawContent:String, parse:Bool = true)
	{
		lines = rawContent.trim().split("\n");
		fields = Type.getInstanceFields(Type.getClass(this));

		// Metadata must be parsed, objects are not needed for a menu right
		parseMetadata();
		parseAudioSamples(); // Oh yeah ofc, another method to parse just a few strings fuck im so dumb ffs
		#if FS_ACCESS convertAudio(); #end

		if (parse == false)
			return;

		this.parseObjects();
	}

	private function parseMetadata()
	{
		for (i in 0...lines.length)
		{
			var section:String = getSection(i);
			var value:String = getSectionValue(i);

			if (value.length > 1 && !exclusions.contains(section) && fields.contains(section))
			{
				Reflect.setField(this, section, value);
				continue;
			}

			if (exclusions.contains(section))
				break;
		}
	}

	// You fucking dumbass, follows the same logic as parseObjects but blocking the section when it hits CustomAudioSamples
	private function parseAudioSamples()
	{
		var lastSection:String = '';
		var sectionBlock:Bool = false; // Block the parser to the current section

		for (i in 0...lines.length)
		{
			var section:String = getSection(i);
			var value:String = getSectionValue(i);

			// Fast skip and get them audio paths quickly
			if (section == "EditorLayers")
				continue;

			if ((lines[i].split(":")[1].length <= 1 || value == "[]" && section != "KeySounds") && !sectionBlock)
			{
				lastSection = section;
				sectionBlock = (section == "CustomAudioSamples");
			}

			if (lastSection != section && section == "- Path")
				CustomAudioSamples.push(Paths.file('quaver/$MapSetId/$value'));

			if (section == "SoundEffects")
				break;
		}
	}

	private function parseObjects()
	{
		var lastSection:String = '';
		var sectionBlock:Bool = false; // Block the parser to the current section

		for (i in 0...lines.length)
		{
			var section:String = getSection(i);
			var value:String = getSectionValue(i);

			// Easy fix wtf
			if ((lines[i].split(":")[1].length <= 1 || value == "[]" && section != "KeySounds") && !sectionBlock)
			{
				lastSection = section;
				sectionBlock = (section == "HitObjects");
			}

			// lil check
			if (lastSection != section && section == "- StartTime")
			{
				// i fucking hate this
				switch (lastSection)
				{
					case "SoundEffects":
						SoundEffects.push({
							StartTime: Std.parseFloat(value),
							Sample: Std.parseInt(getSectionValue(i + 1)),
							Volume: Std.parseInt(getSectionValue(i + 2)) / 100
						});

					case 'TimingPoints':
						TimingPoints.push({
							StartTime: Std.parseFloat(value),
							Bpm: Std.parseFloat(getSectionValue(i + 1))
						});

					case 'SliderVelocities':
						SliderVelocities.push({
							StartTime: Std.parseFloat(value),
							Multiplier: Std.parseFloat(getSectionValue(i + 1))
						});

					case 'HitObjects':
						var hitObj:HitObject = {
							StartTime: Std.parseFloat(value),
							Lane: Std.parseInt(getSectionValue(i + 1)),
							EndTime: 0,
							HitSound: null,
							KeySounds: null
						};

						var secSection:String = getSection(i + 2);
						switch (secSection)
						{
							case 'EndTime':
								hitObj.EndTime = Std.parseFloat(getSectionValue(i + 2));

								// More section checks lol
								switch (getSection(i + 3))
								{
									case "HitSound":
										if (getSectionValue(i + 3).contains(","))
										{
											hitObj.HitSound = getSectionValue(i + 3).split(",")[0]; // select the first one until v1.2
										}
										else hitObj.HitSound = getSectionValue(i + 3);

									case "KeySounds":
										// Surely a KeySound coming next line
										if (getSectionValue(i + 3) != "[]")
										{
											hitObj.KeySounds = {
												Sample: Std.parseInt(getSectionValue(i + 4)),
												Volume: Std.parseInt(getSectionValue(i + 5)) / 100
											};
										}
								}

							case "HitSound":
								if (getSectionValue(i + 2).contains(","))
								{
									hitObj.HitSound = getSectionValue(i + 2).split(",")[0]; // select the first one until v1.2
								}
								else hitObj.HitSound = getSectionValue(i + 2);

							case 'KeySounds':
								// Surely a KeySound coming next line
								if (getSectionValue(i + 2) != "[]")
								{
									hitObj.KeySounds = {
										Sample: Std.parseInt(getSectionValue(i + 3)),
										Volume: Std.parseInt(getSectionValue(i + 4)) / 100
									};
								}
						}
						HitObjects.push(hitObj);
				}
			}
		}
	}

	// Helpers
	#if FS_ACCESS
	private function convertAudio()
	{
		var path = Path.join(IO.getFolderPath(QUAVER), '$MapSetId');
		if (!IO.existsOnFolder(QUAVER, '$MapSetId'))
			sys.FileSystem.createDirectory(path);

		// uhhhhhh
		var audioPath:String = Path.join(Sys.getCwd(), "assets", "funkin", "quaver", '$MapSetId', AudioFile);
		AudioFile = AudioFile.replace("mp3", "ogg");

		var output:String = Path.join(path, AudioFile);
		if (sys.FileSystem.exists(output))
			return;

		var ffmpeg:String = Path.join(Sys.getCwd(), "utils", "ffmpeg.exe");
		if (Sys.command('$ffmpeg -i "$audioPath" -c:a libvorbis -q:a 4 "$output" -y') == 0)
			trace('Finished converting audio file');
	}
	#end

	// Always return a string
	private inline function getSection(i:Int):String
		return lines.unsafeGet(i).split(":")[0].trim();

	private inline function getSectionValue(i:Int):String
		return lines.unsafeGet(i).split(":")[1].trim();
}

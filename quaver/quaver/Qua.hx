package quaver;

using StringTools;

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

	public function new(unparsedContent:String)
	{
		var lines:Array<String> = unparsedContent.trim().split("\n");
		fields = Type.getInstanceFields(Type.getClass(this));

		var lastSection:String = '';

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
			catch (ex)
			{
				trace('Failed parsin Quaver Map $ex');
			}
		}
	}
}
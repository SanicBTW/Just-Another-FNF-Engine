package base;

class MusicBeatState extends ScriptableState implements MusicHandler
{
	public var volume(default, set):Float = 1;
	public var sounds:Array<AudioStream> = [];

	function set_volume(value:Float):Float
	{
		volume = value;
		if (volume > 1)
			volume = 1;
		if (volume < 0)
			volume = 0;
		for (sound in sounds)
			sound.volume = volume;
		return value;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		updateContent(elapsed);
	}

	public function updateContent(elapsed:Float)
	{
		if (Conductor.boundState == this && Conductor.boundSong != null)
			Conductor.updateTimePosition(elapsed);
	}

	public function beatHit() {}

	public function stepHit() {}
}

interface MusicHandler
{
	public var volume(default, set):Float;
	public var sounds:Array<AudioStream>;
	public function updateContent(elapsed:Float):Void;
	public function beatHit():Void;
	public function stepHit():Void;
}

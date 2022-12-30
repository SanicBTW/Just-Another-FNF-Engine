package base;

import base.ScriptableState.ScriptableSubState;

class MusicBeatState extends ScriptableState implements MusicHandler
{
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

class MusicBeatSubState extends ScriptableSubState implements MusicHandler
{
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
	public function updateContent(elapsed:Float):Void;
	public function beatHit():Void;
	public function stepHit():Void;
}

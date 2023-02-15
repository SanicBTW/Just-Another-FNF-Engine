package base;

import base.ScriptableState.ScriptableSubState;
import funkin.ChartLoader.Song;

class MusicBeatState extends ScriptableState implements MusicHandler
{
	public var SONG:Song;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	private function get_curStep():Int
		return Conductor.stepPosition;

	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function update(elapsed:Float)
	{
		updateContent(elapsed);

		super.update(elapsed);
	}

	public function updateContent(elapsed:Float)
	{
		if (Conductor.boundState == this && Conductor.boundSong != null)
			Conductor.updateTimePosition(elapsed);
	}

	public function stepHit() {}

	public function beatHit() {}
}

class MusicBeatSubState extends ScriptableSubState implements MusicHandler
{
	public var SONG:Song;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	private function get_curStep():Int
		return Conductor.stepPosition;

	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function update(elapsed:Float)
	{
		updateContent(elapsed);

		super.update(elapsed);
	}

	public function updateContent(elapsed:Float)
	{
		if (Conductor.boundState == this && Conductor.boundSong != null)
			Conductor.updateTimePosition(elapsed);
	}

	public function stepHit() {}

	public function beatHit() {}
}

interface MusicHandler
{
	public function updateContent(elapsed:Float):Void;
	public var SONG:Song;

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit():Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit():Void;
}

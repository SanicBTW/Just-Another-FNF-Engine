package base;

import base.ScriptableState.ScriptableSubState;
import base.system.Conductor;
import base.system.SoundManager;
import funkin.ChartLoader.Song;

class MusicBeatState extends ScriptableState implements MusicHandler
{
	private var bgMusic:AudioStream;

	public var SONG:Song;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	private function get_curStep():Int
		return Conductor.stepPosition;

	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function create()
	{
		bgMusic = SoundManager.setSound("musicPERSIST");

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (Conductor.boundState == this && Conductor.boundSong != null)
			Conductor.updateTimePosition(elapsed);

		super.update(elapsed);
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
		if (Conductor.boundState == this && Conductor.boundSong != null)
			Conductor.updateTimePosition(elapsed);

		super.update(elapsed);
	}

	public function stepHit() {}

	public function beatHit() {}
}

interface MusicHandler
{
	public var SONG:Song;

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit():Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit():Void;
}

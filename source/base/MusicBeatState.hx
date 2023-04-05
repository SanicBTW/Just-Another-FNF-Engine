package base;

import base.ScriptableState.ScriptableSubState;
import base.system.Conductor;
import flixel.FlxBasic;
import flixel.FlxG;
import funkin.ChartLoader.Song;

// I need a better way to avoid updating time
class MusicBeatState extends ScriptableState implements MusicHandler
{
	public var SONG:Song;
	public var updateTime:Bool = true;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.stepPosition;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function update(elapsed:Float)
	{
		if (Conductor.boundState == this && updateTime)
			Conductor.updateTimePosition(elapsed);

		super.update(elapsed);
	}

	public function stepHit() {}

	public function beatHit() {}
}

class MusicBeatSubState extends ScriptableSubState implements MusicHandler
{
	public var SONG:Song;
	public var updateTime:Bool = true;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.stepPosition;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function update(elapsed:Float)
	{
		if (Conductor.boundState == this && updateTime)
			Conductor.updateTimePosition(elapsed);

		super.update(elapsed);
	}

	public function stepHit() {}

	public function beatHit() {}
}

interface MusicHandler
{
	public var SONG:Song;

	public var updateTime:Bool;

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit():Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit():Void;
}

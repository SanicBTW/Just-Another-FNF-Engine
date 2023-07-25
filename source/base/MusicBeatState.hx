package base;

import flixel.FlxSubState;
import funkin.SongTools.SongData;

class MusicBeatState extends TransitionState implements MusicHandler
{
	public var updateTime:Bool = false;
	@:isVar public var SONG(get, never):SongData;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.stepPosition;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beatPosition;

	@:noCompletion
	private function get_SONG():SongData
		return Conductor.SONG;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (updateTime)
			Conductor.updateTime(elapsed);

		super.update(elapsed);
	}

	override public function destroy()
	{
		Conductor.onStepHit.remove(stepHit);
		Conductor.onBeatHit.remove(beatHit);

		super.destroy();
	}

	public function stepHit() {}

	public function beatHit()
	{
		if (SONG.notes[Std.int(curStep / 16)] != null && SONG.notes[Std.int(curStep / 16)].changeBPM)
			Conductor.changeBPM(SONG.notes[Std.int(curStep / 16)].bpm);
	}
}

class MusicBeatSubState extends FlxSubState implements MusicHandler
{
	public var updateTime:Bool = false;
	@:isVar public var SONG(get, never):SongData;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.stepPosition;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beatPosition;

	@:noCompletion
	private function get_SONG():SongData
		return Conductor.SONG;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (updateTime)
			Conductor.updateTime(elapsed);

		super.update(elapsed);
	}

	override public function destroy()
	{
		Conductor.onStepHit.remove(stepHit);
		Conductor.onBeatHit.remove(beatHit);

		super.destroy();
	}

	public function stepHit() {}

	public function beatHit() {}
}

interface MusicHandler
{
	public var updateTime:Bool;

	public var SONG(get, never):SongData;
	private function get_SONG():SongData;

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit():Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit():Void;
}

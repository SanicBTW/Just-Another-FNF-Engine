package engine;

import backend.Conductor;
import flixel.FlxSubState;
import funkin.Song.SwagSong;

// Move these to FlxState
class MusicBeatState extends TransitionState implements MusicHandler
{
	@:isVar public var updateTime(get, set):Bool;

	@:noCompletion
	private function get_updateTime():Bool
		return Conductor.active;

	@:noCompletion
	private function set_updateTime(state:Bool):Bool
		return Conductor.active = state;

	@:isVar public var SONG(get, never):SwagSong;

	@:noCompletion
	private function get_SONG():SwagSong
		return Conductor.SONG;

	@:isVar public var curStep(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.roundStep;

	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.roundBeat;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		Conductor.update(elapsed);
		super.update(elapsed);
	}

	override public function destroy()
	{
		Conductor.onStepHit.remove(stepHit);
		Conductor.onBeatHit.remove(beatHit);

		super.destroy();
	}

	public function stepHit(step:Int):Void
	{
		setOnModules('curStep', step);
		callOnModules('onStepHit', step);
	}

	public function beatHit(beat:Int)
	{
		if (SONG != null && SONG.notes[Std.int(curStep / 16)] != null && SONG.notes[Std.int(curStep / 16)].changeBPM)
			Conductor.changeBPM(SONG.notes[Std.int(curStep / 16)].bpm);

		setOnModules('curBeat', beat);
		callOnModules('onBeatHit', beat);
	}
}

class MusicBeatSubState extends FlxSubState implements MusicHandler
{
	@:isVar public var updateTime(get, set):Bool;

	@:noCompletion
	private function get_updateTime():Bool
		return Conductor.active;

	@:noCompletion
	private function set_updateTime(state:Bool):Bool
		return Conductor.active = state;

	@:isVar public var SONG(get, never):SwagSong;

	@:noCompletion
	private function get_SONG():SwagSong
		return Conductor.SONG;

	@:isVar public var curStep(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.roundStep;

	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.roundBeat;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		Conductor.update(elapsed);
		super.update(elapsed);
	}

	override public function destroy()
	{
		Conductor.onStepHit.remove(stepHit);
		Conductor.onBeatHit.remove(beatHit);

		super.destroy();
	}

	public function stepHit(step:Int)
	{
		setOnModules('curStep', step);
		callOnModules('onStepHit', step);
	}

	public function beatHit(beat:Int)
	{
		setOnModules('curBeat', beat);
		callOnModules('onBeatHit', beat);
	}
}

interface MusicHandler
{
	public var updateTime(get, set):Bool;

	public var SONG(get, never):SwagSong;
	private function get_SONG():SwagSong;

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit(step:Int):Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit(beat:Int):Void;
}

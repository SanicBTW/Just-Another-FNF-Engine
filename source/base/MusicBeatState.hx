package base;

import backend.Conductor;
import flixel.FlxSubState;
import funkin.SongTools.SongData;

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

	@:isVar public var SONG(get, never):SongData;

	@:noCompletion
	private function get_SONG():SongData
		return Conductor.SONG;

	@:isVar public var curStep(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.step;

	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beat;

	@:isVar public var curSection(get, never):Int = 0;

	@:noCompletion
	private function get_curSection():Int
		return Conductor.section;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);
		Conductor.onSectionHit.add(sectionHit);

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
		Conductor.onSectionHit.remove(sectionHit);
		Conductor.shouldResync = true; // Reset the flag to avoid forgor

		super.destroy();
	}

	public function stepHit(step:Int):Void
	{
		setOnModules('curStep', step);
		callOnModules('onStepHit', step);
	}

	public function beatHit(beat:Int):Void
	{
		if (SONG != null && SONG.notes[Std.int(curStep / 16)] != null && SONG.notes[Std.int(curStep / 16)].changeBPM)
			Conductor.changeBPM(SONG.notes[Std.int(curStep / 16)].bpm);

		setOnModules('curBeat', beat);
		callOnModules('onBeatHit', beat);
	}

	public function sectionHit(section:Int):Void
	{
		setOnModules("curSection", section);
		callOnModules("onSectionHit", section);
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

	@:isVar public var SONG(get, never):SongData;

	@:noCompletion
	private function get_SONG():SongData
		return Conductor.SONG;

	@:isVar public var curStep(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.step;

	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beat;

	@:isVar public var curSection(get, never):Int = 0;

	@:noCompletion
	private function get_curSection():Int
		return Conductor.section;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);
		Conductor.onSectionHit.add(sectionHit);

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
		Conductor.onSectionHit.remove(sectionHit);

		super.destroy();
	}

	public function stepHit(step:Int):Void
	{
		setOnModules('curStep', step);
		callOnModules('onStepHit', step);
	}

	public function beatHit(beat:Int):Void
	{
		setOnModules('curBeat', beat);
		callOnModules('onBeatHit', beat);
	}

	public function sectionHit(section:Int):Void
	{
		setOnModules("curSection", section);
		callOnModules("onSectionHit", section);
	}
}

interface MusicHandler
{
	public var updateTime(get, set):Bool;

	public var SONG(get, never):SongData;
	private function get_SONG():SongData;

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit(step:Int):Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit(beat:Int):Void;

	public var curSection(get, never):Int;
	private function get_curSection():Int;
	public function sectionHit(section:Int):Void;
}

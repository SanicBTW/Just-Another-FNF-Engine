package base;

import base.ScriptableState.ScriptableSubState;
import base.system.Conductor;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import funkin.ChartLoader.Song;

// I need a better way to avoid updating time
class MusicBeatState extends ScriptableState implements MusicHandler
{
	public var updateTime:Bool = true;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.stepPosition;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function create()
	{
		FlxG.debugger.addTrackerProfile(new TrackerProfile(Conductor, [
			"songPosition",
			"sectionPosition",
			"stepPosition",
			"beatPosition",
			"songSpeed",
			"bpm"
		]));
		FlxG.debugger.track(Conductor);

		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (updateTime)
			Conductor.updateTimePosition(elapsed);

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

class MusicBeatSubState extends ScriptableSubState implements MusicHandler
{
	public var updateTime:Bool = true;
	@:isVar public var curStep(get, never):Int = 0;
	@:isVar public var curBeat(get, never):Int = 0;

	@:noCompletion
	private function get_curStep():Int
		return Conductor.stepPosition;

	@:noCompletion
	private function get_curBeat():Int
		return Conductor.beatPosition;

	override public function create()
	{
		Conductor.onStepHit.add(stepHit);
		Conductor.onBeatHit.add(beatHit);

		super.create();
	}

	override public function update(elapsed:Float)
	{
		if (updateTime)
			Conductor.updateTimePosition(elapsed);

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

	public var curStep(get, never):Int;
	private function get_curStep():Int;
	public function stepHit():Void;

	public var curBeat(get, never):Int;
	private function get_curBeat():Int;
	public function beatHit():Void;
}

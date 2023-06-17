package backend;

import flixel.FlxBasic;
import flixel.FlxG;
import lime.app.Event;

typedef BPMChange =
{
	var time:Float;
	var beat:Float;
	var step:Float;
}

@:publicFields
// Extends FlxBasic so it can be automatically called by the state and not manually yknow
class Conductor extends FlxBasic
{
	// Time and steps
	var time(default, set):Float = 0;

	@:noCompletion
	private function set_time(newTime:Float)
	{
		time = newTime;

		if (roundStep > lastStepHit)
		{
			for (step in Math.floor(lastStepHit)...roundStep)
				onStepHit.dispatch(step);

			lastStepHit = roundStep;
		}

		if (roundBeat > lastBeatHit)
		{
			for (beat in Math.floor(lastBeatHit)...roundBeat)
				onBeatHit.dispatch(beat);

			lastBeatHit = roundBeat;
		}

		return time;
	}

	var step(get, null):Float = 0;

	@:noCompletion
	private function get_step()
		return step = lastStep + ((time - lastTime) / stepCrochet);

	var roundStep(get, null):Int = 0;

	@:noCompletion
	private function get_roundStep()
		return roundStep = Math.floor(step);

	var beat(get, null):Float = 0;

	@:noCompletion
	private function get_beat()
		return beat = lastBeat + ((time - lastTime) / crochet);

	var roundBeat(get, null):Int = 0;

	@:noCompletion
	private function get_roundBeat()
		return roundBeat = Math.floor(beat);

	// BPM
	var bpm(default, set):Float = 0;

	@:noCompletion
	private function set_bpm(newBPM:Float)
	{
		crochet = (60 / newBPM) * 1000;
		stepCrochet = crochet / 4; // Do a var of snap divisor or compass scale or that shit dunno i failed music subject lol
		return bpm = newBPM;
	}

	var crochet:Float = 0;
	var stepCrochet:Float = 0;
	var bpmChanges:Array<BPMChange> = [
		{
			step: 0,
			beat: 0,
			time: 0
		}
	];

	// Resync
	final resyncThreshold:Float = 20;

	var lastTime(get, null):Float = 0;

	@:noCompletion
	private function get_lastTime()
		return lastTime = bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].time;

	var lastStep(get, null):Float = 0;

	@:noCompletion
	private function get_lastStep()
		return lastStep = bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].step;

	var lastBeat(get, null):Float = 0;

	@:noCompletion
	private function get_lastBeat()
		return lastBeat = bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].beat;

	@:noCompletion
	var lastStepHit:Int = -1;
	@:noCompletion
	var lastBeatHit:Int = -1;

	// Events
	final onStepHit:Event<Int->Void> = new Event<Int->Void>();
	final onBeatHit:Event<Int->Void> = new Event<Int->Void>();
	final onBPMChange:Event<(Float, Float) -> Void> = new Event<(Float, Float) -> Void>();

	function new(bpm:Float = 100)
	{
		super();

		this.bpm = bpm;
		visible = false;
	}

	function changeBPM(newBPM:Float, dontResetBeat:Bool = true)
	{
		if (crochet != 0 && dontResetBeat)
		{
			bpmChanges.push({
				beat: beat,
				step: step,
				time: time
			});
			bpmChanges.sort((a, b) -> Std.int(a.time - b.time));
		}

		onBPMChange.dispatch(bpm, newBPM);
		bpm = newBPM;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			time += elapsed * 1000;
	}

	override function destroy()
	{
		onStepHit.cancel();
		onBeatHit.cancel();
		onBPMChange.cancel();

		onStepHit.removeAll();
		onBeatHit.removeAll();
		onBPMChange.removeAll();

		super.destroy();
	}
}

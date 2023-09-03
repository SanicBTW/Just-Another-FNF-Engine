package backend;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.SongTools.SongData;
import openfl.media.Sound;

typedef BPMChange =
{
	var time:Float;
	var beat:Float;
	var step:Float;
}

enum BeatDivisor
{
	FOURTHS;
	CROCHET;
}

@:publicFields
class Conductor
{
	// Time and steps
	static var time(default, set):Float = 0;

	@:noCompletion
	private static function set_time(newTime:Float)
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

	static var step(get, null):Float = 0;

	@:noCompletion
	private static function get_step()
		return step = lastStep + ((time - lastTime) / stepCrochet);

	static var roundStep(get, null):Int = 0;

	@:noCompletion
	private static function get_roundStep()
		return roundStep = Math.floor(step);

	static var beat(get, null):Float = 0;

	@:noCompletion
	private static function get_beat()
		return beat = lastBeat + ((time - lastTime) / crochet);

	static var roundBeat(get, null):Int = 0;

	@:noCompletion
	private static function get_roundBeat()
		return roundBeat = Math.floor(beat);

	// BPM
	static var bpm(default, set):Float = 0;

	@:noCompletion
	private static function set_bpm(newBPM:Float)
	{
		crochet = (60 / newBPM) * 1000;
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}

	static var crochet(default, null):Float = 0;
	static var stepCrochet(default, null):Float = 0;
	static var bpmChanges:Array<BPMChange> = [
		{
			step: 0,
			beat: 0,
			time: 0
		}
	];

	// Resync
	static final resyncThreshold:Float = 30;

	static var lastTime(get, null):Float = 0;

	@:noCompletion
	private static function get_lastTime()
		return lastTime = bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].time;

	static var lastStep(get, null):Float = 0;

	@:noCompletion
	private static function get_lastStep()
		return lastStep = bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].step;

	static var lastBeat(get, null):Float = 0;

	@:noCompletion
	private static function get_lastBeat()
		return lastBeat = bpmChanges.length == 0 ? 0 : bpmChanges[bpmChanges.length - 1].beat;

	@:noCompletion
	static var lastStepHit(default, null):Int = -1;
	@:noCompletion
	static var lastBeatHit(default, null):Int = -1;

	// Events
	static var onStepHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	static var onBeatHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	static var onBPMChange(default, null):FlxTypedSignal<(Float, Float) -> Void> = new FlxTypedSignal<(Float, Float) -> Void>();

	// LifeTime
	static var active:Bool = false;

	// FNF - Speed
	static var speed(default, set):Float;

	@:noCompletion
	private static function set_speed(value:Float):Float
		return speed = rate * value;

	static var rate:Float = 0.45;

	// FNF - Resync & Data
	static var boundInst:FlxSound;
	static var boundVocals:FlxSound;
	static var SONG:SongData;

	// FNF - Input
	static var safeFrames:Int = 10;
	static var safeZoneOffset:Float = (safeFrames / 60) * 1000;
	static var timeScale:Float = safeZoneOffset / 166;

	static function bindSong(newData:SongData, newInst:Sound, ?newVocals:Sound)
	{
		boundInst = new FlxSound().loadEmbedded(newInst);
		boundVocals = new FlxSound();
		if (newVocals != null)
			boundVocals = new FlxSound().loadEmbedded(newVocals);

		FlxG.sound.list.add(boundInst);
		FlxG.sound.list.add(boundVocals);

		SONG = newData;
		changeBPM(SONG.bpm);
		speed = SONG.speed;
	}

	static function changeBPM(newBPM:Float, dontResetBeat:Bool = true)
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

	static function update(elapsed:Float)
	{
		if (!active)
			return;

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			if (Math.abs(FlxG.sound.music.time - time) > resyncThreshold)
				resyncMusic();

			time += elapsed * 1000;
		}

		if (boundInst != null && boundInst.playing)
		{
			if (Math.abs(boundInst.time - time) > resyncThreshold
				|| (SONG.needsVoices && Math.abs(boundVocals.time - time) > resyncThreshold))
				resyncFNF();

			time += elapsed * 1000;
		}
	}

	// Force Flixel BGMusic Resync
	static function resyncMusic()
	{
		trace('Resyncing song time ${FlxG.sound.music.time}, $time');

		FlxG.sound.music.play();
		time = FlxG.sound.music.time;

		trace('New song time ${FlxG.sound.music.time}, $time');
	}

	// Force FNF Song Resync
	static function resyncFNF()
	{
		trace('Resyncing song time ${boundInst.time}, $time');
		if (SONG.needsVoices)
			boundVocals.pause();

		boundInst.play();
		time = boundInst.time;
		if (SONG.needsVoices)
		{
			boundVocals.time = time;
			boundVocals.play();
		}
		trace('New song time ${boundInst.time}, $time');
	}

	static function reset()
	{
		SONG = null;
		time = 0;
		step = 0;
		roundStep = 0;
		beat = 0;
		roundBeat = 0;
		bpmChanges = [
			{
				step: 0,
				beat: 0,
				time: 0
			}
		];
		lastTime = 0;
		lastStep = 0;
		lastBeat = 0;
		lastStepHit = 0;
		lastBeatHit = 0;
	}
}

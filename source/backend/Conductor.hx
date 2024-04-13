package backend;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.SongTools.SongData;
import openfl.media.Sound;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

// Rewritten once again but using the 0.2.7.1A Conductor with some newer changes (https://github.com/SanicBTW/Just-Another-FNF-Engine/tree/a118fe49424d27eafa25cdb9f13bc8645b343c6d)

@:publicFields
class Conductor
{
	// Time, steps, beats and sections
	static var time:Float = 0;
	public static var section:Int = 0;
	public static var step:Int = 0;
	public static var beat:Int = 0;

	// BPM
	static var bpm(default, set):Float = 0;

	@:noCompletion
	private static function set_bpm(newBPM:Float)
	{
		crochet = calculateCrochet(newBPM);
		stepCrochet = crochet / 4;
		return bpm = newBPM;
	}

	static var crochet(default, null):Float = 0;
	static var stepCrochet(default, null):Float = 0;
	static var bpmChanges:Array<BPMChangeEvent> = [];

	// Resync
	static var shouldResync:Bool = true; // Flag to avoid resyncing on some states, only affects music
	static final resyncThreshold:Float = 50;

	@:noCompletion
	static var lastStepHit(default, null):Int = -1;
	@:noCompletion
	static var lastBeatHit(default, null):Int = -1;
	@:noCompletion
	static var lastSectionHit(default, null):Int = -1;

	// Events
	static var onStepHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	static var onBeatHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	static var onSectionHit(default, null):FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	static var onBPMChange(default, null):FlxTypedSignal<(Float, Float) -> Void> = new FlxTypedSignal<(Float, Float) -> Void>();

	// LifeTime
	static var active:Bool = false;

	// If it should work even if an audio device doesn't exists
	// TODO: Finish callbacks not firing when the song finishes
	static var force:Bool = false; // Search for a better name or sum

	// FNF - Speed
	static var speed(default, set):Float;

	@:noCompletion
	private static function set_speed(value:Float):Float
		return speed = flixel.math.FlxMath.roundDecimal(rate * value, 2);

	static var rate:Float = 0.45;

	// FNF - Resync & Data
	static var boundInst:FlxSound;
	static var boundVocals:FlxSound;
	static var SONG:SongData;

	// FNF - Input
	static var safeFrames:Int = 10;
	static var safeZoneOffset:Float = (safeFrames / 60) * 1000;
	// 166 is normalized since its 10 secs / 60 frames but what about higher framerates and shit
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
		// she a keeper :money_mouth: (idk how this works to be honest)
		// (15 min later) ok so this basically its just a way to avoid parsing bpm changes when parsing the chart, and add the bpm changes mid song, pretty cool if i can say so
		if (crochet != 0 && dontResetBeat)
		{
			bpmChanges.push({
				stepTime: step,
				songTime: time,
				bpm: newBPM,
				stepCrochet: stepCrochet
			});
			bpmChanges.sort((a, b) -> Std.int(a.songTime - b.songTime));
		}

		onBPMChange.dispatch(bpm, newBPM);
		bpm = newBPM;
	}

	static function update(elapsed:Float)
	{
		if (!active)
			return;

		if (force)
		{
			time += elapsed * 1000;

			if (FlxG.sound.music != null)
				FlxG.sound.music.time = time;

			if (boundInst != null)
				boundInst.time = time;

			return;
		}

		// no need to calculate sections in here
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			step = Math.floor(time / stepCrochet);
			beat = Math.floor(step / 4);

			if (shouldResync && Math.abs(FlxG.sound.music.time - time) > resyncThreshold)
				resyncMusic();

			if (step > lastStepHit)
			{
				onStepHit.dispatch(step);
				lastStepHit = step;
			}

			if (beat > lastBeatHit)
			{
				if (step % 4 == 0)
					onBeatHit.dispatch(beat);
				lastBeatHit = beat;
			}

			time += elapsed * 1000;
		}

		if (boundInst != null && boundInst.playing)
		{
			var lastChange:BPMChangeEvent = getBPMFromSeconds(time);

			step = lastChange.stepTime + Math.floor((time - lastChange.songTime) / stepCrochet);
			section = Math.floor(step / 16); // aint no way :sob:
			beat = Math.floor(step / 4);

			if (step > lastStepHit)
			{
				if (Math.abs(boundInst.time - time) > resyncThreshold
					|| (SONG.needsVoices && Math.abs(boundVocals.time - time) > resyncThreshold))
					resyncFNF();

				onStepHit.dispatch(step);
				lastStepHit = step;
			}

			if (beat > lastBeatHit)
			{
				if (step % 4 == 0)
					onBeatHit.dispatch(beat);
				lastBeatHit = beat;
			}

			// Psych rollback?
			if (section > lastSectionHit)
			{
				onSectionHit.dispatch(section);
				lastSectionHit = section;
			}

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
		bpmChanges = [];
		time = 0;
		step = 0;
		beat = 0;
		section = 0;
		lastStepHit = -1;
		lastBeatHit = -1;
		lastSectionHit = -1;
		onStepHit.removeAll();
		onBeatHit.removeAll();
		onSectionHit.removeAll();
		onBPMChange.removeAll();
	}

	static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};

		for (i in 0...Conductor.bpmChanges.length)
		{
			if (time >= Conductor.bpmChanges[i].songTime)
				lastChange = Conductor.bpmChanges[i];
		}

		return lastChange;
	}

	static inline function calculateCrochet(bpm:Float)
		return (60 / bpm) * 1000;
}

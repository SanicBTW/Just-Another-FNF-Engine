package base;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.tweens.*;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.ChartLoader;
import funkin.SongTools.SongData;
import funkin.notes.Note;
import openfl.media.Sound;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

// TODO: Separate vocals?
// The same old conductor lol
class Conductor
{
	// Time and speed
	public static var songPosition:Float = 0;
	public static var songSpeed(default, set):Float;
	public static var songRate:Float = 0.45;
	private static var speedTwn:FlxTween;
	// easy enough
	public static var speedBasedBPM:Bool = true;

	// Steps and beats
	public static var stepPosition:Int = 0;
	public static var beatPosition:Int = 0;

	// Resyncing
	public static final comparisonThreshold:Float = 30;
	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	// BPM
	public static var bpm:Float = 0;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;
	public static var bpmChanges:Array<BPMChangeEvent> = [];

	// Audio
	public static var boundInst:FlxSound;
	public static var boundVocals:FlxSound;

	// The song data
	public static var SONG:SongData;

	// Event listeners
	public static var onStepHit:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
	public static var onBeatHit:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	// Input
	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = (safeFrames / 60) * 1000;
	public static var timeScale:Float = safeZoneOffset / 166;

	public function new() {}

	public static function updateTime(elapsed:Float)
	{
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			stepPosition = Math.floor(songPosition / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				onStepHit.dispatch();
				lastStep = stepPosition;
			}

			if (beatPosition > lastBeat)
			{
				if (stepPosition % 4 == 0)
					onBeatHit.dispatch();
				lastBeat = beatPosition;
			}

			songPosition += elapsed * 1000;
		}

		if (boundInst != null && boundInst.playing)
		{
			var lastChange:BPMChangeEvent = getBPMFromSeconds(songPosition);

			stepPosition = lastChange.stepTime + Math.floor((songPosition - lastChange.songTime) / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				if (Math.abs(boundInst.time - songPosition) > comparisonThreshold
					|| (SONG.needsVoices && Math.abs(boundVocals.time - songPosition) > comparisonThreshold))
					resyncTime();

				onStepHit.dispatch();
				lastStep = stepPosition;
			}

			if (beatPosition > lastBeat)
			{
				if (stepPosition % 4 == 0)
					onBeatHit.dispatch();
				lastBeat = beatPosition;
			}

			songPosition += elapsed * 1000;
		}
	}

	public static function bindSong(newData:SongData, newInst:Sound, ?newVocals:Sound)
	{
		boundInst = new FlxSound().loadEmbedded(newInst);
		boundVocals = new FlxSound();
		if (newVocals != null)
			boundVocals = new FlxSound().loadEmbedded(newVocals);

		FlxG.sound.list.add(boundInst);
		FlxG.sound.list.add(boundVocals);

		SONG = newData;
		changeBPM(SONG.bpm);
		songSpeed = songRate * SONG.speed;

		reset();
	}

	@:noCompletion
	private static function set_songSpeed(value:Float):Float
	{
		if (ChartLoader.noteQueue.length <= 0 || ChartLoader.noteQueue[0] == null || speedBasedBPM == false)
			return songSpeed = value;

		if (speedTwn != null)
			speedTwn.cancel();

		// 0.2 would fit osu i guess
		speedTwn = FlxTween.num(songSpeed, value, 0.5, {
			ease: FlxEase.linear,
			onComplete: (_) ->
			{
				speedTwn = null;
			}
		}, function(f:Float)
		{
			songSpeed = f;
			for (note in ChartLoader.noteQueue)
			{
				note.updateSustainScale();
			}
		});

		return value;
	}

	public static function changeBPM(newBPM:Float)
	{
		bpm = newBPM;

		crochet = calculateCrochet(newBPM);
		stepCrochet = (crochet / 4);

		if (SONG == null)
			return;

		var baseSpeed:Float = songRate * SONG.speed;

		if (speedBasedBPM)
		{
			var bps:Float = (bpm / 60) / songRate;

			var nearestNote:Note = ChartLoader.noteQueue[0];
			var noteDiff:Float = 1;
			if (nearestNote != null)
				noteDiff = (nearestNote.strumTime - songPosition) / 1000;

			songSpeed = baseSpeed * (bps / noteDiff);
		}
		else
		{
			if (songSpeed != baseSpeed)
				songSpeed = baseSpeed;
		}
	}

	public static function resyncTime()
	{
		trace('Resyncing song time ${boundInst.time}, $songPosition');
		if (SONG.needsVoices)
			boundVocals.pause();

		boundInst.play();
		songPosition = boundInst.time;
		if (SONG.needsVoices)
		{
			boundVocals.time = songPosition;
			boundVocals.play();
		}
		trace('New song time ${boundInst.time}, $songPosition');
	}

	public static function getBPMFromSeconds(time:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};

		for (i in 0...bpmChanges.length)
		{
			if (time >= bpmChanges[i].songTime)
				lastChange = bpmChanges[i];
		}

		return lastChange;
	}

	public static function getBPMFromStep(step:Float):BPMChangeEvent
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};

		for (i in 0...Conductor.bpmChanges.length)
		{
			if (Conductor.bpmChanges[i].stepTime <= step)
				lastChange = Conductor.bpmChanges[i];
		}

		return lastChange;
	}

	public static function getCrochetAtTime(time:Float):Float
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepCrochet * 4;
	}

	public static function beatToSeconds(beat:Float):Float
	{
		var step = beat * 4;
		var lastChange = getBPMFromStep(step);
		return lastChange.songTime + ((step - lastChange.stepTime) / (lastChange.bpm / 60) / 4) * 1000;
	}

	public static function getStep(time:Float):Float
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + (time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getStepRounded(time:Float):Float
	{
		var lastChange = getBPMFromSeconds(time);
		return lastChange.stepTime + Math.floor(time - lastChange.songTime) / lastChange.stepCrochet;
	}

	public static function getBeat(time:Float):Float
	{
		return getStep(time) / 4;
	}

	public static function getBeatRounded(time:Float):Int
	{
		return Math.floor(getStep(time) / 4);
	}

	public static inline function calculateCrochet(bpm:Float)
		return (60 / bpm) * 1000;

	public static function reset()
	{
		songPosition = 0;
		stepPosition = 0;
		beatPosition = 0;
		lastStep = -1;
		lastBeat = -1;
	}
}

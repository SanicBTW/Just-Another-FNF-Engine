package base;

import flixel.FlxG;
import flixel.system.FlxSound;
import flixel.util.FlxSignal.FlxTypedSignal;
import funkin.SongTools.SongData;
import openfl.media.Sound;

// TODO: Separate vocals?
// The same old conductor lol
class Conductor
{
	// Time
	public static var songPosition:Float = 0;

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
			stepPosition = Math.floor(songPosition / stepCrochet);
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

		SONG = newData;

		FlxG.sound.list.add(boundInst);
		FlxG.sound.list.add(boundVocals);

		changeBPM(SONG.bpm);

		reset();
	}

	public static function changeBPM(newBPM:Float)
	{
		bpm = newBPM;

		crochet = calculateCrochet(newBPM);
		stepCrochet = (crochet / 4);
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

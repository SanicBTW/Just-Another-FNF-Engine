package base.system;

import base.MusicBeatState.MusicHandler;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.system.FlxSound;
import funkin.ChartLoader;
import funkin.notes.Note;
import openfl.media.Sound;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	// song shit
	public static var songPosition:Float = 0;
	public static var songSpeed(default, set):Float = 2;

	// sections, steps and beats
	public static var sectionPosition:Int = 0;
	public static var stepPosition:Int = 0;
	public static var beatPosition:Int = 0;

	// for resync??
	public static final comparisonThreshold:Float = 30;
	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	// bpm shit
	public static var bpm:Float = 0;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	// the audio shit and the state
	public static var boundSong:FlxSound;
	public static var boundVocals:FlxSound;
	public static var boundState:MusicHandler;

	// note stuff
	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000);
	public static var timeScale:Float = safeZoneOffset / 166;

	public function new() {}

	public static function bindSong(newState:MusicHandler, newSong:Sound, bpm:Float, ?newVocals:Sound)
	{
		boundSong = new FlxSound().loadEmbedded(newSong);
		boundVocals = new FlxSound();
		if (newVocals != null)
			boundVocals = new FlxSound().loadEmbedded(newVocals);
		boundState = newState;

		FlxG.sound.list.add(boundSong);
		FlxG.sound.list.add(boundVocals);

		changeBPM(bpm);

		reset();
	}

	private static function set_songSpeed(value:Float):Float
	{
		// IS THERE SOME WAY TO GET RID OF 0.45 *
		var ratio:Float = value / songSpeed;
		songSpeed = value;
		for (note in ChartLoader.unspawnedNoteList)
		{
			note.updateSustainScale(ratio);
		}
		return value;
	}

	public static function changeBPM(newBPM:Float)
	{
		bpm = newBPM;

		crochet = calculateCrochet(newBPM);
		stepCrochet = (crochet / 4);

		if (boundState.SONG != null)
		{
			// and xmod basically works by basing the speed on the bpm.
			// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
			// bps is calculated by bpm / 60
			// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
			// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
			// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
			var baseSpeed:Float = 0.45 * boundState.SONG.speed;
			var bps:Float = (bpm / 60) / 0.45;
			var curNote:Note = ChartLoader.unspawnedNoteList[0];
			var noteDiff:Float = (curNote.strumTime - (stepPosition / stepCrochet)) / 1000;
			songSpeed = baseSpeed * (bps * noteDiff) / 0.45;
		}
	}

	public static function updateTimePosition(elapsed:Float)
	{
		if (FlxG.sound.music.playing)
		{
			stepPosition = Math.floor(songPosition / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				boundState.stepHit();
				lastStep = stepPosition;
			}

			if (beatPosition > lastBeat)
			{
				if (stepPosition % 4 == 0)
					boundState.beatHit();
				lastBeat = beatPosition;
			}

			songPosition += elapsed * 1000;
		}

		if (boundSong != null && boundSong.playing)
		{
			var lastChange:BPMChangeEvent = getBPMFromSeconds(songPosition);

			stepPosition = lastChange.stepTime + Math.floor((songPosition - lastChange.songTime) / stepCrochet);
			sectionPosition = Math.floor(stepPosition / 16);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				if (Math.abs(boundSong.time - songPosition) > comparisonThreshold
					|| (boundState.SONG.needsVoices && Math.abs(boundVocals.time - songPosition) > comparisonThreshold))
					resyncTime();

				boundState.stepHit();
				lastStep = stepPosition;
			}

			if (beatPosition > lastBeat)
			{
				if (stepPosition % 4 == 0)
					boundState.beatHit();
				lastBeat = beatPosition;
			}

			songPosition += elapsed * 1000;
		}
	}

	public static function resyncTime()
	{
		trace('Resyncing song time ${boundSong.time}, $songPosition');
		if (boundState.SONG.needsVoices)
			boundVocals.pause();

		boundSong.play();
		songPosition = boundSong.time;
		if (boundState.SONG.needsVoices)
		{
			boundVocals.time = songPosition;
			boundVocals.play();
		}
		trace('New song time ${boundSong.time}, $songPosition');
	}

	public static function getBPMFromSeconds(time:Float)
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: bpm,
			stepCrochet: stepCrochet
		};

		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (time >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange;
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

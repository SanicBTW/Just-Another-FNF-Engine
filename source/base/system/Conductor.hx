package base.system;

import base.MusicBeatState.MusicHandler;
import base.system.SoundManager.AudioStream;
import funkin.ChartLoader;
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
	public static var boundSong:AudioStream;
	public static var boundVocals:AudioStream;
	public static var boundState:MusicHandler;

	// note stuff
	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000);
	public static var timeScale:Float = safeZoneOffset / 166;

	public function new() {}

	public static function bindSong(newState:MusicHandler, newSong:Sound, bpm:Float, ?newVocals:Sound)
	{
		boundSong = new AudioStream();
		boundSong.audioSource = newSong;
		SoundManager.setSound("inst", boundSong);
		boundVocals = new AudioStream();
		if (newVocals != null)
		{
			boundVocals.audioSource = newVocals;
			SoundManager.setSound("voices", boundVocals);
		}
		boundState = newState;

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
			songSpeed = 0.45 * boundState.SONG.speed;
	}

	public static function updateTimePosition(elapsed:Float)
	{
		if (boundSong.isPlaying)
		{
			var lastChange:BPMChangeEvent = getBPMFromSeconds(songPosition);

			stepPosition = lastChange.stepTime + Math.floor((songPosition - lastChange.songTime) / stepCrochet);
			sectionPosition = Math.floor(stepPosition / 16);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				if (boundSong.tag != "musicPERSIST")
				{
					if ((Math.abs(boundSong.playbackTime - songPosition) > comparisonThreshold)
						|| (boundVocals != null
							&& boundVocals.audioSource != null
							&& Math.abs(boundVocals.playbackTime - songPosition) > comparisonThreshold))
						resyncTime();
				}

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
		trace('Resyncing song time ${boundSong.playbackTime}, $songPosition');
		if (boundVocals != null && boundVocals.audioSource != null)
			boundVocals.stop();

		boundSong.play();
		songPosition = boundSong.playbackTime;
		if (boundVocals != null && boundVocals.audioSource != null)
		{
			boundVocals.playbackTime = songPosition;
			boundVocals.play();
		}
		trace('New song time ${boundSong.playbackTime}, $songPosition');
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

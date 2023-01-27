package base;

import base.MusicBeatState.MusicHandler;
import base.SoundManager.AudioStream;
import funkin.ChartLoader.Song;
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

	// steps and beats
	public static var stepPosition:Int = 0;
	public static var beatPosition:Int = 0;

	// for resync??
	public static final comparisonThreshold:Float = 20;
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

	public function new() {}

	public static function bindSong(newState:MusicHandler, newSong:Sound, songBPM:Float, ?newVocals:Sound)
	{
		boundSong = new AudioStream();
		boundSong.source = newSong;
		SoundManager.addSound(boundSong);
		// boundVocals = new AudioStream(); // gotta test this
		if (newVocals != null)
		{
			boundVocals = new AudioStream();
			boundVocals.source = newVocals;
			SoundManager.addSound(boundVocals);
		}
		boundState = newState;

		changeBPM(songBPM);

		songPosition = 0;
		stepPosition = 0;
		beatPosition = 0;
		lastStep = -1;
		lastBeat = -1;
	}

	public static function mapBPMChanges(song:Song)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length)
		{
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM,
					stepCrochet: calculateCrochet(curBPM) / 4
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += (calculateCrochet(curBPM) / 4) * deltaSteps;
		}
	}

	public static function changeBPM(newBPM:Float)
	{
		bpm = newBPM;

		crochet = (60 / bpm) * 1000;
		stepCrochet = crochet / 4;
	}

	public static function updateTimePosition(elapsed:Float)
	{
		if (boundSong.playing)
		{
			songPosition += elapsed * 1000;

			var lastChange:BPMChangeEvent = getBPMFromSeconds(songPosition);

			stepPosition = Math.floor(lastChange.stepTime / lastChange.stepCrochet)
				- Math.floor((songPosition - lastChange.stepTime) / lastChange.stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);

			if (stepPosition > lastStep)
			{
				if ((Math.abs(boundSong.time - songPosition) > comparisonThreshold)
					|| (boundVocals != null && Math.abs(boundVocals.time - songPosition) > comparisonThreshold))
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
		}
	}

	public static function resyncTime()
	{
		trace('Resyncing song time ${boundSong.time}');
		if (boundVocals != null)
			boundVocals.stop();

		boundSong.play();
		songPosition = boundSong.time;
		if (boundVocals != null)
		{
			boundVocals.time = songPosition;
			boundVocals.play();
		}
		trace('New song time $songPosition');
	}

	inline public static function calculateCrochet(bpm:Float)
		return (60 / bpm) * 1000;

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
}

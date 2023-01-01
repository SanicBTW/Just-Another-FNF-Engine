package base;

import base.MusicBeatState.MusicHandler;
import base.Song.SwagSong;
import base.SoundManager.AudioStream;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
	@:optional var stepCrochet:Float;
}

class Conductor
{
	public static var songPosition:Float = 0;
	public static var bpm:Float = 0;
	public static var crochet:Float = ((60 / bpm) * 1000);
	public static var stepCrochet:Float = crochet / 4;

	public static var safeZoneOffset:Float = Math.floor((10 /* safe frames */ / 60) * 1000);
	public static var timeScale:Float = safeZoneOffset / 166;
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static var stepPosition:Int = 0;
	public static var beatPosition:Int = 0;

	public static var lastStep:Float = -1;
	public static var lastBeat:Float = -1;

	public static var boundSong:AudioStream;
	public static var boundVocals:AudioStream;
	public static var boundState:MusicHandler;

	public function new() {}

	public static function recalculateTimings() {}

	public static function bindSong(newState:MusicHandler, newSong:AudioStream, songBPM:Float, ?newVocals:AudioStream)
	{
		boundSong = newSong;
		SoundManager.addSound(boundSong);
		if (newVocals != null)
		{
			boundVocals = newVocals;
			SoundManager.addSound(boundVocals);
		}
		boundState = newState;

		changeBPM(songBPM);

		songPosition = 0;
		lastStep = -1;
		lastBeat = -1;
	}

	public static function mapBPMChanges(song:SwagSong)
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
					stepCrochet: ((60 / curBPM) * 1000) / 4
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
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

			stepPosition = Math.floor(songPosition / stepCrochet);
			beatPosition = Math.floor(stepPosition / 4);
			if (stepPosition > lastStep)
			{
				if ((Math.abs(boundSong.time - songPosition) > 20)
					|| (boundVocals != null && Math.abs(boundVocals.time - songPosition) > 20))
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
		songPosition = boundSong.time;
		if (boundVocals != null)
		{
			boundVocals.stop();
			boundVocals.time = songPosition;
			boundVocals.play();
		}
		trace('New song time $songPosition');
	}
}

package states;

import base.Conductor;
import base.MusicBeatState;
import base.Song;
import base.SoundManager.AudioStream;
import funkin.Note;

class PlayTest extends MusicBeatState
{
	public static var SONG:SwagSong;

	override function create()
	{
		Paths.clearStoredMemory();

		SONG = Song.loadFromJSON("bopeebo");

		var shitinst = new AudioStream();
		var shitvoices = new AudioStream();
		shitinst.source = Paths.inst("bopeebo");
		shitvoices.source = Paths.voices("bopeebo");
		Conductor.bindSong(this, shitinst, SONG.bpm, shitvoices);

		var noteshit1 = new Note(0, 2);
		noteshit1.screenCenter();
		add(noteshit1);

		super.create();

		Conductor.boundSong.play();
		Conductor.boundVocals.play();
		Conductor.resyncTime();

		Paths.clearUnusedMemory();
	}
}
